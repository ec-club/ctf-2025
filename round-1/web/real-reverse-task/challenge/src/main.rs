use actix_web::{App, HttpRequest, HttpResponse, HttpServer, Responder, get, middleware::Logger};
use crc16::{ARC, State};
use log::{debug, error, info};

mod magic;

#[get("/flag")]
async fn get_flag(req: HttpRequest) -> impl Responder {
    let conn_info = req.connection_info();
    let client_ip = conn_info.realip_remote_addr(); // I trust Traefik this time… I cannot be betrayed twice…
    if client_ip.is_none() {
        error!("Could not determine client IP.");
        return HttpResponse::InternalServerError().body("Please create a thread in Discord.");
    }
    let hash = State::<ARC>::calculate(client_ip.unwrap().as_bytes());
    if hash != 0xBEEF {
        debug!("Rejecting request from IP: {}", client_ip.unwrap());
        debug!("Computed hash: {:04X}", hash);
        return HttpResponse::Forbidden().body("Access denied");
    }

    let flag = magic::generate_flag();
    info!("Releasing flag {} for IP: {}", flag, client_ip.unwrap());
    return HttpResponse::Ok().body(flag);
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    HttpServer::new(|| App::new().wrap(Logger::default()).service(get_flag))
        .bind(("0.0.0.0", port.parse::<u16>().unwrap()))?
        .run()
        .await
}
