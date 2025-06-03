-- Add migration script here
CREATE TABLE IF NOT EXISTS feature_relations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id TEXT NOT NULL,
    feature_id TEXT NOT NULL,

    FOREIGN KEY (event_id) REFERENCES events(id),
    FOREIGN KEY (feature_id) REFERENCES features(id)
);
