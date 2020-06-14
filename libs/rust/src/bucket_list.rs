use std::alloc::{alloc, dealloc, Layout};
use std::marker::PhantomData;
use std::ptr::NonNull;
use std::{cmp, mem, ptr, slice, str};

const BUCKET_SIZE: usize = 128;

#[repr(C)]
pub struct BucketListInner {
    pub next: *mut BucketListInner,
    pub end: *mut u8,
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
    unsafe fn bump_size_align(bump: *mut u8, end: *mut u8, layout: Layout) -> Result<Bump, ()> {
        let required_offset = bump.align_offset(layout.align());
        println!("required offset is: {}", required_offset);
        if required_offset == usize::MAX {
            return Err(());
        }

        let bump = bump.add(required_offset);
        let end_alloc = bump.add(layout.size());
        if end_alloc as usize > end as usize {
            println!("bump failed: need to allocate new buffer");
            return Err(());
        }

        return Ok(Bump {
            ptr: NonNull::new_unchecked(bump),
            next_bump: NonNull::new_unchecked(end_alloc),
        });
    }

    pub unsafe fn alloc(&mut self, layout: Layout) -> *mut u8 {
        let array_begin = &mut self.array_begin as *mut () as *mut u8;
        let bucket_end = array_begin.add(BUCKET_SIZE);

        if let Ok(Bump { ptr, next_bump }) = Self::bump_size_align(self.end, bucket_end, layout) {
            self.end = next_bump.as_ptr();
            return ptr.as_ptr();
        }

        if !self.next.is_null() {
            return (&mut *self.next).alloc(layout);
        }

        println!("allocating new buffer");

        let bucket_align = cmp::max(layout.align(), mem::align_of::<BucketListInner>());
        let inner_size = cmp::max(bucket_align, mem::size_of::<BucketListInner>());
        let bucket_size = inner_size + cmp::max(BUCKET_SIZE, layout.size());

        let next_layout = match Layout::from_size_align(bucket_size, bucket_align) {
            Ok(x) => x,
            Err(_) => return ptr::null_mut(),
        };

        self.next = alloc(next_layout) as *mut BucketListInner;
        let next = self.next.as_mut().unwrap();
        let next_array_begin = &mut next.array_begin as *mut () as *mut u8;
        next.next = ptr::null_mut();
        next.end = next_array_begin.add(layout.size());
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
            new.data.next = ptr::null_mut();
            new.data.end = &mut new.data.array_begin as *mut () as *mut u8;
            return new;
        }
    }

    pub fn add<T>(&mut self, t: T) -> &'a mut T {
        unsafe {
            let location = self.data.alloc(Layout::new::<T>()) as *mut T;
            ptr::write(location, t);
            return &mut *location;
        }
    }

    pub fn add_array<T>(&mut self, vec: Vec<T>) -> &'a mut [T] {
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

    pub fn add_slice<T>(&mut self, slice: &[T]) -> &'a mut [T]
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

    pub fn add_str(&mut self, values: &str) -> &'a mut str {
        let values = values.as_bytes();
        return unsafe { str::from_utf8_unchecked_mut(self.add_slice(values)) };
    }

    pub fn clear<'b, 'c>(buckets: &'a mut BucketList<'a>) -> &'c mut BucketList<'b> {
        let mut bucket = &mut buckets.data as *mut BucketListInner;

        while !bucket.is_null() {
            let current = unsafe { &mut *bucket };
            current.end = &mut current.array_begin as *mut () as *mut u8;
            bucket = current.next;
        }

        return unsafe { mem::transmute(buckets) };
    }
}

#[test]
fn test_bucket_list() {
    // TODO make this work with concurrency/compile time checks
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

    let bucket_list = BucketList::clear(bucket_list);
}
