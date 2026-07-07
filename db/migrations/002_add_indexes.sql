-- 002_add_indexes.sql
--
-- Optimizes:
--   SELECT org_id, status, COUNT(*), SUM(amount)
--   FROM hotel_bookings
--   WHERE city = 'delhi'
--     AND created_at >= NOW() - INTERVAL '30 days'
--   GROUP BY org_id, status;
--
-- The query filters on (city, created_at) and only ever reads
-- org_id, status and amount besides those two filter columns.
-- A single composite index on the filter columns, with the
-- remaining columns carried as INCLUDE (covering index), lets
-- Postgres satisfy the WHERE clause with an index range scan and
-- answer org_id/status/amount straight from the index without a
-- heap fetch (index-only scan, assuming the visibility map is
-- up to date after VACUUM).
--
-- city is listed first because it is an equality filter (more
-- selective, narrows to one B-tree branch); created_at is second
-- because it is a range filter and benefits from being the
-- trailing sorted key within each city.
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

-- booking_events is looked up by booking_id in normal application
-- access patterns (fetch events for a booking), so index the FK.
CREATE INDEX IF NOT EXISTS idx_booking_events_booking_id
    ON booking_events (booking_id);
