use std::fs;
use std::net::SocketAddr;
use std::sync::Arc;
use rand::Rng;
use clap::Parser;
use tokio::io::AsyncWrite;
use tokio::io::AsyncWriteExt;
use tokio::net::TcpStream;
use tokio::net::TcpListener;
use tokio::task::JoinHandle;
use tokio_rustls::TlsAcceptor;
use tokio_rustls::server::TlsStream;
use rustls::server::ServerConfig;
use rustls::pki_types::PrivateKeyDer;
use rustls::pki_types::CertificateDer;
use rustls_pemfile::certs;
use rustls_pemfile::private_key;

#[derive(Parser, Clone, Debug)]
#[command(version, about = include_str!("../LICENSE_HEADER"))]
struct Arguments {
    #[arg(short = 'b', long, default_value = "0.0.0.0")]
    #[arg(help = "The IP address to bind, pass '0.0.0.0' for all interfaces")]
    host: String,

    #[arg(short = 'p', long, default_value_t = 17)]
    #[arg(help = "The port servicing RFC 865 QOTD over TCP, pass '0' to disable")]
    port: u16,

    #[arg(long, default_value_t = 787)]
    #[arg(help = "The port servicing RFC 865 QOTD over TLS, pass '0' do disable SSL/TLS.")]
    ssl_port: u16,

    #[arg(long, default_value = "ssl.crt")]
    #[arg(help = "Path of PEM-encoded TLS certificate chain")]
    ssl_cert: String,

    #[arg(long, default_value = "ssl.key")]
    #[arg(help = "Path of PEM-encoded TLS private key")]
    ssl_key: String,

    #[arg(long, default_value_t = 17)]
    #[arg(help = "The port servicing RFC 865 QOTD over UDP, pass '0' to disable")]
    udp_port: u16,

    #[arg(short = 'd', long, default_value = "database.txt")]
    #[arg(help = "Path of the quote database")]
    db: String,

    #[arg(long, default_value = "default")]
    #[arg(help = r#"The format of the quote database. Available values:
     <char>:   use the character passed as delimiter
    'default': use 30*'-' as delimiter"#)]
    db_format: String,
}

#[tokio::main]
async fn main() {
    println!("Copyright (C) 2024 Joseph Chris, Mozilla Public License 2.0");
    println!("rqotdd - Rust Quote of the Day (QOTD) Daemon");
    let args: Arguments = Arguments::parse();
    let addr_tcp: String = format!("{}:{}", args.host, args.port);
    let addr_ssl: String = format!("{}:{}", args.host, args.ssl_port);
    let addr_udp: String = format!("{}:{}", args.host, args.udp_port);
    let database: Vec<String> = load_database(&args.db, &args.db_format);
    let mut tasks: Vec<JoinHandle<()>> = Vec::new();

    if args.port != 0 {
        let database = database.clone();
        tasks.push(tokio::spawn(async move {
            listen_tcp(addr_tcp, &database).await;
        }));
    }

    if args.ssl_port != 0 {
        let server_config: ServerConfig = build_tls_server(&args.ssl_cert, &args.ssl_key);
        let database = database.clone();
        tasks.push(tokio::spawn(async move {
            listen_ssl(addr_ssl, &database, Arc::new(server_config)).await;
        }));
    }

    if args.udp_port != 0 {
        tasks.push(tokio::spawn(async move {
            let database = database.clone();
            listen_udp(addr_udp, &database).await;
        }));
    }

    for task in tasks {
        task.await.unwrap();
    }
}

async fn listen_tcp(addr: String, db: &Vec<String>) {
    let listener: TcpListener = TcpListener::bind(&addr).await.unwrap();
    println!("Listening on tcp://{}", addr);
    loop {
        let (stream, peer) = listener.accept().await.unwrap();
        let db: Vec<String> = db.clone();
        tokio::spawn(async move {
            handle_connection("TCP", stream, peer, db).await;
        });
    }
}

async fn listen_ssl(addr: String, db: &Vec<String>, server_config: Arc<ServerConfig>) {
    let listener: TcpListener = TcpListener::bind(&addr).await.unwrap();
    println!("Listening on tls://{}", addr);
    loop {
        let (stream, peer) = listener.accept().await.unwrap();
        let server_config: Arc<ServerConfig> = server_config.clone();
        let db: Vec<String> = db.clone();
        tokio::spawn(async move {
            let acceptor: TlsAcceptor = TlsAcceptor::from(server_config);
            let stream: TlsStream<TcpStream> = acceptor.clone().accept(stream).await.unwrap();
            handle_connection("SSL", stream, peer, db).await;
        });
    }
}

async fn listen_udp(addr: String, db: &Vec<String>) {
    let listener: tokio::net::UdpSocket = tokio::net::UdpSocket::bind(&addr).await.unwrap();
    println!("Listening on udp://{}", addr);
    loop {
        let mut buf: [u8; 1] = [0; 1];
        let (_, peer): (usize, SocketAddr) = listener.recv_from(&mut buf).await.unwrap();
        let response: String = format!("\n{}\n\n\x00", get_random_entry(&db));
        println!("[UDP] FROM {}:{} RESPONSE SIZE {}", peer.ip(), peer.port(), response.len());
        listener.send_to(response.as_bytes(), &peer).await.unwrap();
    }
}

async fn handle_connection<T>(scheme: &str, mut stream: T, peer: SocketAddr, db: Vec<String>) where T: AsyncWrite + Unpin {
    let response: String = format!("\n{}\n\n", get_random_entry(&db));
    println!("[{}] FROM {}:{} RESPONSE SIZE {}", scheme, peer.ip(), peer.port(), response.len());
    stream.write_all(response.as_bytes()).await.unwrap();
    stream.shutdown().await.unwrap();
}

fn load_database(filename: &str, format: &str) -> Vec<String> {
    let binding = fs::read_to_string(filename).unwrap();
    let db: &str = binding.as_str();
    let delimiter: &str = match format {
        "default" => "------------------------------",
        _ => format,
    };
    db
        .trim()
        .split(&delimiter)
        .collect::<Vec<&str>>()
        .iter()
        .map(|x| x.trim().to_string())
        .collect::<Vec<String>>()
}

fn get_random_entry(db: &Vec<String>) -> String {
    let mut rng = rand::thread_rng();
    let random = rng.gen_range(0..db.len());
    db[random].to_string()
}

fn build_tls_server(cert_filename: &str, key_filename: &str) -> ServerConfig {
    let _ = rustls::crypto::ring::default_provider().install_default();
    let cert_file: fs::File = fs::File::open(cert_filename).unwrap();
    let key_file: fs::File = fs::File::open(key_filename).unwrap();

    let mut cert_reader: std::io::BufReader<fs::File> = std::io::BufReader::new(cert_file);
    let mut key_reader: std::io::BufReader<fs::File> = std::io::BufReader::new(key_file);

    let cert: Vec<CertificateDer<'static>> = certs(&mut cert_reader)
        .collect::<std::io::Result<Vec<CertificateDer<'static>>>>()
        .unwrap();
    let key: PrivateKeyDer<'_> = private_key(&mut key_reader)
        .map(|key| key.unwrap())
        .unwrap();
    ServerConfig::builder_with_protocol_versions(&vec![&rustls::version::TLS12, &rustls::version::TLS13])
        .with_no_client_auth()
        .with_single_cert(cert, key)
        .unwrap()
}
