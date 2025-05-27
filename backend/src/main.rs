use axum::{
    Json, Router,
    extract::{Path, State},
    routing::{get, post, put},
};
use dotenvy::dotenv;
use hyper::StatusCode;
use serde::{Deserialize, Serialize};
use sqlx::{Pool, Row, Sqlite, SqlitePool, sqlite::SqlitePoolOptions};
use std::env;
use tokio;
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use uuid::Uuid;

#[derive(Clone)]
struct AppState {
    db: Pool<Sqlite>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
struct Event {
    id: String,
    name: String,
}

#[tokio::main]
async fn main() {
    dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .init();

    let db_url = env::var("DATABASE_URL").unwrap();
    let db = SqlitePoolOptions::new().connect(&db_url).await.unwrap();

    let _ = sqlx::migrate!("./migrations").run(&db).await;

    let state = AppState { db };

    let app = Router::new()
        .route(
            "/api/events",
            get(get_events).post(create_event).put(update_event),
        )
        .route("/api/events/{id}", get(get_event))
        .with_state(state)
        .layer(TraceLayer::new_for_http());

    let listener = tokio::net::TcpListener::bind("0.0.0.0:5000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn create_event(State(state): State<AppState>, name: String) -> Json<Event> {
    let id = Uuid::new_v4().to_string();
    sqlx::query("INSERT INTO events (id, name) VALUES (?, ?)")
        .bind(&id)
        .bind(&name)
        .execute(&state.db)
        .await
        .unwrap();

    Json(Event { id, name })
}

async fn get_event(Path(id): Path<String>, State(state): State<AppState>) -> Json<Event> {
    let row = sqlx::query("SELECT name FROM events WHERE id = ?")
        .bind(&id)
        .fetch_one(&state.db)
        .await
        .unwrap();

    let name: String = row.get("name");

    Json(Event { id, name })
}

async fn get_events(State(state): State<AppState>) -> Result<Json<Vec<Event>>, StatusCode> {
    let rows = sqlx::query_as::<_, Event>("SELECT id, name FROM events")
        .fetch_all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(rows))
}

async fn update_event(
    State(state): State<AppState>,
    Json(data): Json<Event>,
) -> Result<StatusCode, StatusCode> {
    sqlx::query("UPDATE events SET name = ? WHERE id = ?")
        .bind(&data.name)
        .bind(&data.id)
        .execute(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::NO_CONTENT)
}
