mod gen;

use std::fs::File;
use std::path::PathBuf;
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(name = "mcgen", about = "Microcode generator for MIPS-X.")]
struct Opt {
    /// Path to signal definition file.
    #[structopt(short, long)]
    definition: PathBuf,

    /// Path to microcode source file.
    #[structopt(short, long)]
    microcode: PathBuf,
}

fn main() {
    let opt = Opt::from_args();

    let cd_file = File::open(&opt.definition).unwrap();
    let mc_file = File::open(&opt.microcode).unwrap();

    let cd: gen::ControlDefinition = serde_yaml::from_reader(&cd_file).unwrap();
    let mc: gen::Microcode = serde_yaml::from_reader(&mc_file).unwrap();

    let rom = gen::generate_rom(&cd, &mc).unwrap();
    for inst in &rom {
        println!("{:016x}", inst);
    }
}
