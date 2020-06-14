use std::alloc::{alloc, dealloc, Layout};
use std::marker::PhantomData;
use std::ptr::NonNull;
use std::sync::atomic::{AtomicPtr, Ordering};
use std::{cmp, mem, ptr, slice, str};

const BUCKET_SIZE: usize = 128;

#[repr(C)]
pub struct BucketListInner {
    pub next: AtomicPtr<BucketListInner>,
    pub end: AtomicPtr<u8>,
    pub array_begin: (),
}

struct Bump {
    ptr: NonNull<u8>,
    next_bump: NonNull<u8>,
}

#[repr(C)]
pub struct BucketList<'a> {
    unused: PhantomData<&'a u8>,
    pub data: BucketListInner,
}

impl BucketListInner {
    unsafe fn bump_size_align(bump: *const u8, end: *const u8, layout: Layout) -> Result<Bump, ()> {
        let required_offset = bump.align_offset(layout.align());
        if required_offset == usize::MAX {
            return Err(());
        }

        let bump = bump.add(required_offset);
        let end_alloc = bump.add(layout.size());
        if end_alloc as usize > end as usize {
            return Err(());
        }

        return Ok(Bump {
            ptr: NonNull::new_unchecked(bump as *mut u8),
            next_bump: NonNull::new_unchecked(end_alloc as *mut u8),
        });
    }

    pub unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        let array_begin = &self.array_begin as *const () as *const u8;
        let bucket_end = array_begin.add(BUCKET_SIZE);
        let mut bump = self.end.load(Ordering::SeqCst);

        while let Ok(Bump { ptr, next_bump }) = Self::bump_size_align(bump, bucket_end, layout) {
            if let Err(ptr) = self.end.compare_exchange_weak(
                bump,
                next_bump.as_ptr(),
                Ordering::SeqCst,
                Ordering::SeqCst,
            ) {
                bump = ptr;
            } else {
                return ptr.as_ptr();
            }
        }

        let next = self.next.load(Ordering::SeqCst);
        if !next.is_null() {
            return (&*next).alloc(layout);
        }

        let bucket_align = cmp::max(layout.align(), mem::align_of::<BucketListInner>());
        let inner_size = cmp::max(bucket_align, mem::size_of::<BucketListInner>());
        let bucket_size = inner_size + cmp::max(BUCKET_SIZE, layout.size());

        let next_layout = match Layout::from_size_align(bucket_size, bucket_align) {
            Ok(x) => x,
            Err(_) => return ptr::null_mut(),
        };

        let new_buffer = &mut *(alloc(next_layout) as *mut BucketListInner);
        let next_array_begin = &mut new_buffer.array_begin as *mut () as *mut u8;
        new_buffer.next = AtomicPtr::new(ptr::null_mut());
        new_buffer.end = AtomicPtr::new(next_array_begin.add(layout.size()));

        let mut target = &self.next;
        while let Err(ptr) = target.compare_exchange_weak(
            ptr::null_mut(),
            new_buffer,
            Ordering::SeqCst,
            Ordering::SeqCst,
        ) {
            target = &(&*ptr).next;
        }

        return next_array_begin;
    }
}

impl<'a> BucketList<'a> {
    pub fn new<'b>() -> &'a mut BucketList<'a> {
        unsafe {
            let bucket_align = mem::align_of::<BucketListInner>();
            let bucket_size = mem::size_of::<BucketListInner>() + BUCKET_SIZE;
            let next_layout = Layout::from_size_align_unchecked(bucket_size, bucket_align);
            let new = &mut *(alloc(next_layout) as *mut BucketList);
            new.data.next = AtomicPtr::new(ptr::null_mut());
            new.data.end = AtomicPtr::new(&mut new.data.array_begin as *mut () as *mut u8);
            return new;
        }
    }

    pub fn add<T>(&'a self, t: T) -> &'a mut T {
        unsafe {
            let location = self.data.alloc(Layout::new::<T>()) as *mut T;
            ptr::write(location, t);
            return &mut *location;
        }
    }

    pub fn add_array<T>(&'a self, vec: Vec<T>) -> &'a mut [T] {
        unsafe {
            let len = vec.len();
            let layout =
                Layout::from_size_align_unchecked(mem::size_of::<T>() * len, mem::align_of::<T>());
            let block = self.data.alloc(layout) as *mut T;
            let mut location = block;
            for t in vec {
                ptr::write(location, t);
                location = location.add(1);
            }
            return slice::from_raw_parts_mut(block, len);
        }
    }

    pub fn add_slice<T>(&'a self, slice: &[T]) -> &'a mut [T]
    where
        T: Clone,
    {
        unsafe {
            let len = slice.len();
            let layout =
                Layout::from_size_align_unchecked(mem::size_of::<T>() * len, mem::align_of::<T>());
            let block = self.data.alloc(layout) as *mut T;
            let mut location = block;
            for t in slice {
                ptr::write(location, t.clone());
                location = location.add(1);
            }
            return slice::from_raw_parts_mut(block, len);
        }
    }

    pub fn add_str(&'a self, values: &str) -> &'a mut str {
        let values = values.as_bytes();
        return unsafe { str::from_utf8_unchecked_mut(self.add_slice(values)) };
    }

    pub fn clear<'b, 'c>(buckets: &'a mut BucketList<'a>) -> &'c mut BucketList<'b> {
        let mut bucket = &mut buckets.data as *mut BucketListInner;

        while !bucket.is_null() {
            let current = unsafe { &mut *bucket };
            current.end = AtomicPtr::new(&mut current.array_begin as *mut () as *mut u8);
            bucket = current.next.load(Ordering::SeqCst);
        }

        return unsafe { mem::transmute(buckets) };
    }

    pub fn dealloc(buckets: &'a mut BucketList<'a>) {
        let mut bucket = &mut buckets.data as *mut BucketListInner;

        while !bucket.is_null() {
            let current = unsafe { &mut *bucket };
            let allocated_size = current.end.load(Ordering::SeqCst) as usize
                - &mut current.array_begin as *mut () as usize;
            let allocated_size = cmp::max(allocated_size, BUCKET_SIZE);
            let allocated_size = allocated_size + mem::size_of::<BucketListInner>();
            let next_bucket = current.next.load(Ordering::SeqCst);
            unsafe {
                dealloc(
                    bucket as *mut u8,
                    Layout::from_size_align_unchecked(allocated_size, 1),
                );
            }
            bucket = next_bucket;
        }
    }
}

#[test]
fn test_bucket_list() {
    let bucket_list = BucketList::new();
    let vec = bucket_list.add(Vec::<u64>::new());
    let num = bucket_list.add(12);
    vec.push(*num);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);
    bucket_list.add_array(vec![12, 12, 31, 4123, 123, 5, 14, 5, 134, 5]);

    vec.push(1);

    BucketList::dealloc(bucket_list);
}
