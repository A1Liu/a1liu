use std::alloc::{alloc, dealloc, Layout};
use std::marker::PhantomData;
use std::{cmp, mem, ptr};

const BUCKET_SIZE: usize = 1024 * 1024;

#[repr(C)]
pub struct BucketListInner {
    pub next: *mut BucketListInner,
    pub end: *mut u8,
    pub array_begin: (),
}

#[repr(C)]
pub struct BucketList<'a> {
    unused: PhantomData<&'a u8>,
    pub data: BucketListInner,
}

impl BucketListInner {
    pub unsafe fn add_unsafe(&mut self, layout: Layout) -> *mut u8 {
        if layout.size() > BUCKET_SIZE {
            if self.next.is_null() {
                let next_layout = match Layout::from_size_align(
                    layout.size() + mem::size_of::<BucketListInner>(),
                    cmp::max(layout.align(), mem::align_of::<BucketListInner>()),
                ) {
                    Ok(x) => x,
                    Err(_) => return ptr::null_mut(),
                };

                self.next = alloc(next_layout) as *mut BucketListInner;
                let next = self.next.as_mut().unwrap();
                let next_array_begin = &mut next.array_begin as *mut () as *mut u8;
                next.next = ptr::null_mut();
                next.end = next_array_begin.add(layout.size());
                return next_array_begin;
            } else {
                return (&mut *self.next).add_unsafe(layout);
            }
        }
        return 0 as *mut u8;
    }
}
