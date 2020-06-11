use std::alloc::{alloc, dealloc, Layout};
use std::marker::PhantomData;
use std::mem::size_of;
use std::ptr;
use std::slice::from_raw_parts_mut;
use std::str::from_utf8_unchecked_mut;

const BUCKET_SIZE: usize = 1024 * 1024;

#[derive(Clone, Copy)]
pub struct Bucket {
    begin: *mut u8,
    end: *mut u8,
}

pub struct BucketArray<'a> {
    pub buckets: Vec<Bucket>,
    unused: PhantomData<&'a u8>,
}

impl<'a> BucketArray<'a> {
    pub fn new() -> Self {
        let begin =
            unsafe { alloc(Layout::from_size_align(BUCKET_SIZE, 8).expect("this is an error")) };
        return Self {
            buckets: vec![Bucket { begin, end: begin }],
            unused: PhantomData,
        };
    }

    pub unsafe fn add_unsafe(&mut self, size: usize) -> *mut u8 {
        // @Correctness panics in debug mode without this check
        let size = if size != 0 {
            (size - 1) / 16 * 16 + 16
        } else {
            size
        };

        if size > BUCKET_SIZE {
            let bucket = self.buckets.last().unwrap().clone();
            let begin = alloc(Layout::from_size_align_unchecked(size, 8));
            *self.buckets.last_mut().unwrap() = Bucket {
                begin,
                end: begin.add(size),
            };
            self.buckets.push(bucket);
            return begin;
        }

        let mut last_bucket = self.buckets.last_mut().unwrap();
        let space_left = BUCKET_SIZE - ((last_bucket.end as usize) - (last_bucket.begin as usize));
        if space_left < size {
            let begin = alloc(Layout::from_size_align_unchecked(BUCKET_SIZE, 8));
            self.buckets.push(Bucket { begin, end: begin });
            last_bucket = self.buckets.last_mut().unwrap();
        }

        let ret_location = last_bucket.end;
        last_bucket.end = last_bucket.end.add(size);
        return ret_location;
    }

    pub fn add<T>(&mut self, t: T) -> &'a mut T {
        unsafe {
            let location = self.add_unsafe(size_of::<T>()) as *mut T;
            ptr::write(location, t);
            return &mut *location;
        };
    }

    pub fn add_str(&mut self, values: &str) -> &'a mut str {
        let values = values.as_bytes();
        let len = values.len();
        let begin = unsafe { self.add_unsafe(values.len()) };
        let mut location = begin;
        for value in values {
            unsafe {
                *location = *value;
                location = location.add(1);
            }
        }

        return unsafe { from_utf8_unchecked_mut(from_raw_parts_mut(begin, len)) };
    }

    pub fn add_array<T>(&mut self, values: Vec<T>) -> &'a mut [T] {
        let size = size_of::<T>();
        let len = values.len();
        let begin = unsafe { self.add_unsafe(values.len() * size) as *mut T };
        let mut location = begin;
        for value in values {
            unsafe {
                ptr::write(location, value);
                location = location.add(1);
            }
        }

        return unsafe { from_raw_parts_mut(begin, len) };
    }

    /// Hands back all memory to the allocator.
    pub fn drop(self) {
        for bucket in &self.buckets {
            unsafe {
                let mut size = (bucket.end as usize) - (bucket.begin as usize);
                if size <= BUCKET_SIZE {
                    size = BUCKET_SIZE
                }

                dealloc(bucket.begin, Layout::from_size_align_unchecked(size, 8));
            }
        }
    }

    /// Hands back buckets to the allocator, while maintaining the array of buckets itself.
    pub fn clear<'b>(mut self) -> BucketArray<'b> {
        for bucket in &self.buckets {
            unsafe {
                let mut size = (bucket.end as usize) - (bucket.begin as usize);
                if size <= BUCKET_SIZE {
                    size = BUCKET_SIZE
                }

                dealloc(bucket.begin, Layout::from_size_align_unchecked(size, 8));
            }
        }
        self.buckets.clear();
        return BucketArray {
            buckets: self.buckets,
            unused: PhantomData,
        };
    }
}
