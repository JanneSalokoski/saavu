use axum::{
    Json, Router,
    extract::{Path, State},
    http::StatusCode,
    routing::get,
};
use dotenvy::dotenv;
use serde::{Deserialize, Serialize};
use sqlx::{Pool, Row, Sqlite, sqlite::SqlitePoolOptions};
use std::env;
use tokio;
use tower_http::{services::ServeDir, trace::TraceLayer};
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

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
struct CreateEvent {
    name: String,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
struct Feature {
    id: String,
    name: String,
    description: String,
}

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
struct CreateFeature {
    name: String,
    description: String,
}

fn ensure_db_file_exists(db_url: &str) {
    if let Some(path) = db_url.strip_prefix("sqlite:") {
        let path = std::path::Path::new(path);
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).expect("Failed to create database directory")
        }

        if !path.exists() {
            std::fs::File::create(path).expect("Failed to create db file");
        }
    }
}

#[tokio::main]
async fn main() {
    dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::fmt::layer())
        .init();

    let db_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    ensure_db_file_exists(&db_url);

    // std::thread::sleep(std::time::Duration::from_secs(60 * 10));

    let db = SqlitePoolOptions::new()
        .connect(&db_url)
        .await
        .expect("Failed to connect to db");

    let _ = sqlx::migrate!("./migrations")
        .run(&db)
        .await
        .expect("Failed to run migrations");

    let state = AppState { db };

    let app = Router::new()
        .route(
            "/api/events",
            get(get_events).post(create_event).put(update_event),
        )
        .route("/api/events/{id}", get(get_event))
        .route(
            "/api/features",
            get(get_features).post(create_feature).put(update_feature),
        )
        .route("/api/features/{id}", get(get_feature))
        .nest_service("/app", ServeDir::new("../static"))
        .with_state(state)
        .layer(TraceLayer::new_for_http());

    let listener = tokio::net::TcpListener::bind("0.0.0.0:5000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn create_event(State(state): State<AppState>, Json(data): Json<CreateEvent>) -> Json<Event> {
    let id = Uuid::new_v4().to_string();
    sqlx::query("INSERT INTO events (id, name) VALUES (?, ?)")
        .bind(&id)
        .bind(&data.name)
        .execute(&state.db)
        .await
        .unwrap();

    // to-do: add location headers

    Json(Event {
        id: id,
        name: data.name,
    })
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

// Features

async fn create_feature(
    State(state): State<AppState>,
    Json(data): Json<CreateFeature>,
) -> Json<Feature> {
    let id = Uuid::new_v4().to_string();
    sqlx::query("INSERT INTO features (id, name, description) VALUES (?, ?, ?)")
        .bind(&id)
        .bind(&data.name)
        .bind(&data.description)
        .execute(&state.db)
        .await
        .unwrap();

    // to-do: add location headers

    Json(Feature {
        id: id,
        name: data.name,
        description: data.description,
    })
}

async fn get_feature(Path(id): Path<String>, State(state): State<AppState>) -> Json<Feature> {
    let row =
        sqlx::query_as::<_, Feature>("SELECT id, name, description FROM features WHERE id = ?")
            .bind(&id)
            .fetch_one(&state.db)
            .await
            .unwrap();

    Json(row)
}

async fn get_features(State(state): State<AppState>) -> Result<Json<Vec<Feature>>, StatusCode> {
    let rows = sqlx::query_as::<_, Feature>("SELECT id, name, description FROM features")
        .fetch_all(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(rows))
}

async fn update_feature(
    State(state): State<AppState>,
    Json(data): Json<Feature>,
) -> Result<StatusCode, StatusCode> {
    sqlx::query("UPDATE features SET name = ?, description = ? WHERE id = ?")
        .bind(&data.name)
        .bind(&data.description)
        .bind(&data.id)
        .execute(&state.db)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::NO_CONTENT)
}
