use axum::{
    response::Html,
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tower_http::compression::CompressionLayer;

#[tokio::main]
async fn main() {
    // 2024 Standard Router with Gzip
    let app = Router::new()
        .route("/", get(index))
        .route("/load-notes", get(load_notes))
        .layer(CompressionLayer::new().gzip(true));

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("🚀 NotesLab-Web 2024 Edition: http://localhost:8080");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn index() -> Html<&'static str> {
    Html(r#"
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>NotesLab Web 2024</title>
        <script src="https://unpkg.com/htmx.org@1.9.10"></script>
        <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-gray-900 text-white p-10">
        <div class="max-w-xl mx-auto">
            <h1 class="text-3xl font-bold mb-6 text-purple-400">NotesLab Web</h1>
            
            <div class="bg-gray-800 p-6 rounded-lg shadow-lg">
                <button class="bg-purple-600 hover:bg-purple-500 px-4 py-2 rounded font-bold transition"
                        hx-get="/load-notes" 
                        hx-target="#notes-list">
                    Fetch Notes
                </button>

                <div id="notes-list" class="mt-6 space-y-2">
                    <p class="text-gray-500 italic">Ready to fetch...</p>
                </div>
            </div>
        </div>
    </body>
    </html>
    "#)
}

async fn load_notes() -> Html<String> {
    // Demo content jo noteslab-data se aayega
    let notes = vec!["Rust 2024 Logic", "Joplin Sync Ready", "Axum 0.7 Fast"];
    
    let mut html = String::new();
    for note in notes {
        html.push_str(&format!(
            "<div class='p-3 bg-gray-700 rounded border-l-4 border-purple-500'>{}</div>", 
            note
        ));
    }
    Html(html)
}
