use core::alloc::Layout;
use core::{mem, ptr};

const BITSET_LENGTH: usize = 32;
const FRIDGE_LENGTH: usize = BITSET_LENGTH * 8;

pub struct Fridge<BlockSize> {
    bitset: [u8; BITSET_LENGTH],
    fridge: [BlockSize; FRIDGE_LENGTH],
}

impl<BlockSize> Fridge<BlockSize> {
    pub fn init(&mut self) {
        for byte in self.bitset.iter_mut() {
            *byte = 0;
        }
    }

    pub fn first_trailing_zero(mut byte: u8) -> i8 {
        byte = !byte;
        for i in 0..8 {
            if byte | (1 << i) != 0 {
                return i;
            }
        }
        return -1;
    }

    pub fn alloc(&mut self, layout: Layout) -> *mut u8 {
        if layout.size().max(layout.align()) > mem::size_of::<BlockSize>() {
            return ptr::null_mut();
        }

        for (byte_idx, byte) in self.bitset.iter_mut().enumerate() {
            let idx = Self::first_trailing_zero(*byte);
            if idx < 0 {
                continue;
            }
            *byte = *byte | (1 << idx);

            return &mut self.fridge[byte_idx * 8 + idx as usize] as *mut BlockSize as *mut u8;
        }
        return ptr::null_mut();
    }

    pub fn dealloc(&mut self, ptr: *mut u8, _: Layout) {
        let ptr = ptr as usize;
        let heap_begin = &self.fridge[0] as *const BlockSize as usize;
        let heap_end = &self.fridge[FRIDGE_LENGTH - 1] as *const BlockSize as usize;
        if ptr < heap_begin || ptr >= heap_end {
            return;
        }

        let idx = (ptr - heap_begin) / mem::size_of::<BlockSize>();
        let byte_idx = idx / 8;
        let bit_idx = idx % 8;
        let byte = &mut self.bitset[byte_idx];
        *byte = *byte & !(1 << bit_idx);
    }
}
