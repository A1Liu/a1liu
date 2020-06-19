extern crate alloc;

use alloc::alloc::{alloc, dealloc, realloc};
use core::alloc::Layout;
use core::ops::*;
use core::{mem, ptr, slice};

pub const INITIAL_SIZE: usize = 16;

pub struct Vec<T> {
    pub begin: *mut T,
    pub end: usize,
    pub capacity: usize,
}

impl<T> Vec<T> {
    pub fn new() -> Self {
        Self {
            begin: ptr::null_mut(),
            end: 0,
            capacity: 0,
        }
    }

    pub fn push(&mut self, t: T) {
        if self.begin.is_null() {
            self.capacity = INITIAL_SIZE;
            let cap_bytes = self.capacity * mem::size_of::<T>();
            let layout = Layout::from_size_align(cap_bytes, mem::align_of::<T>())
                .expect("type is messed up man");
            self.begin = unsafe { alloc(layout) as *mut T };
        }

        if self.end == self.capacity {
            let new_cap = self.capacity / 2 + self.capacity;
            let cap_bytes = self.capacity * mem::size_of::<T>();
            let new_cap_bytes = new_cap * mem::size_of::<T>();
            let layout = Layout::from_size_align(cap_bytes, mem::align_of::<T>())
                .expect("vec has grown too large");
            self.begin = unsafe { realloc(self.begin as *mut u8, layout, new_cap_bytes) as *mut T };
            self.capacity = new_cap;
        }

        unsafe { *self.begin.add(self.end) = t }
        self.end += 1;
    }

    pub fn clear(&mut self) {
        for t in self.iter_mut() {
            mem::drop(t);
        }
        self.end = 0;
    }

    pub fn len(&self) -> usize {
        self.end
    }
}

impl<T> Drop for Vec<T> {
    fn drop(&mut self) {
        self.clear();
        unsafe {
            let layout = Layout::from_size_align_unchecked(
                self.capacity * mem::size_of::<T>(),
                mem::align_of::<T>(),
            );
            dealloc(self.begin as *mut u8, layout);
        }
    }
}

impl<T> DerefMut for Vec<T> {
    fn deref_mut(&mut self) -> &mut [T] {
        unsafe { slice::from_raw_parts_mut(self.begin, self.end) }
    }
}

impl<T> Deref for Vec<T> {
    type Target = [T];

    fn deref(&self) -> &[T] {
        unsafe { slice::from_raw_parts(self.begin, self.end) }
    }
}

impl<T> Index<usize> for Vec<T> {
    type Output = T;
    fn index(&self, idx: usize) -> &T {
        return &self.deref()[idx];
    }
}

impl<T> IndexMut<usize> for Vec<T> {
    fn index_mut(&mut self, idx: usize) -> &mut T {
        return &mut self.deref_mut()[idx];
    }
}

impl<T> Index<Range<usize>> for Vec<T> {
    type Output = [T];
    fn index(&self, idx: Range<usize>) -> &[T] {
        return &self.deref()[idx];
    }
}

impl<T> IndexMut<Range<usize>> for Vec<T> {
    fn index_mut(&mut self, idx: Range<usize>) -> &mut [T] {
        return &mut self.deref_mut()[idx];
    }
}
