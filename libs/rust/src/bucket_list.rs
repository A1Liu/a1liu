use std::alloc::{alloc, dealloc, Layout};
use std::marker::PhantomData;
use std::ptr::NonNull;
use std::{cmp, mem, ptr};

const BUCKET_SIZE: usize = 1024 * 1024;

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
        if required_offset == usize::MAX {
            return Err(());
        }

        let bump = bump.add(required_offset);
        let end_alloc = bump.add(layout.size());
        if end_alloc as usize > end as usize {
            return Err(());
        }

        return Ok(Bump {
            ptr: NonNull::new_unchecked(bump),
            next_bump: NonNull::new_unchecked(end_alloc),
        });
    }

    pub unsafe fn add_unsafe(&mut self, layout: Layout) -> *mut u8 {
        let array_begin = &mut self.array_begin as *mut () as *mut u8;
        let bucket_end = array_begin.add(BUCKET_SIZE);

        if let Ok(Bump { ptr, next_bump }) = Self::bump_size_align(self.end, bucket_end, layout) {
            self.end = next_bump.as_ptr();
            return ptr.as_ptr();
        }

        if !self.next.is_null() {
            return (&mut *self.next).add_unsafe(layout);
        }

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
        next.end = (self.next as *mut u8).add(bucket_size + layout.size());
        return next_array_begin;
    }
}
