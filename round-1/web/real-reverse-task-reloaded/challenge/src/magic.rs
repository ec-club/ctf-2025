use nanoid::nanoid;

pub fn generate_flag() -> String {
    let flag_template = std::env::var("FLAG").unwrap();
    return flag_template
        .replace("$1", &nanoid!(8).to_string())
        .replace("$2", &nanoid!(16).to_string())
        .replace("$3", &nanoid!(8).to_string());
}
