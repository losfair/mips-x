use serde::{Serialize, Deserialize};
use std::collections::BTreeMap;

/// Definitions of control signals.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ControlDefinition {
    /// Mappings from signals to their bit indices.
    /// 
    /// Valid bit indices are `[0..=63]`
    pub signals: BTreeMap<String, u8>, // (name, bit_index)
}

/// Instruction Prefix -> Control Signal mappings.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Microcode {
    /// Length of the control prefix in bits, in the instruction.
    pub prefix_len: u32,

    /// Mappings from instruction prefixes to their control signals.
    pub instructions: BTreeMap<String, Vec<String>>,
}

#[derive(Debug, Clone)]
pub enum GenError {
    PrefixTooLong,
    InvalidSignalName,
    InvalidSignalBitIndex,
}

pub fn generate_rom(
    cd: &ControlDefinition,
    mc: &Microcode,
) -> Result<Vec<u64>, GenError> {
    if mc.prefix_len > 16 {
        return Err(GenError::PrefixTooLong);
    }

    let mc_size = (1u32 << mc.prefix_len) as usize;

    // set highest bit by default, to indicate an undefined instruction.
    let mut out = vec![1u64 << 63; mc_size];

    for i in 0..mc_size {
        // FIXME: Left-padding zeros in a more elegant way?
        let mut key = format!("{:b}", i);
        while key.len() < mc.prefix_len as usize {
            key = "0".to_string() + &key;
        }

        if let Some(x) = mc.instructions.get(&key) {
            let mut sig = 0u64;
            for elem in x.iter() {
                let bitindex = match cd.signals.get(elem) {
                    Some(&x) => x,
                    None => return Err(GenError::InvalidSignalName),
                };
                if bitindex >= 64 {
                    return Err(GenError::InvalidSignalBitIndex);
                }
                sig |= 1u64 << bitindex;
            }
            out[i] = sig;
        }
    }

    Ok(out)
}