-- ============================================
-- Operation Swift Recovery - Cybersecurity Incident Database
-- Schema Creation Script
-- Generated: 2026-04-16T10:33:55.032Z
-- ============================================
Create DATABASE IF NOT EXISTS globaltrust_incident;
Use globaltrust_incident;
-- Drop existing tables if they exist
DROP TABLE IF EXISTS attack_logs;
DROP TABLE IF EXISTS ip_intelligence;
DROP TABLE IF EXISTS affected_services;
DROP TABLE IF EXISTS incident_timeline;

-- ============================================
-- Table: affected_services
-- Purpose: Stores information about bank services targeted in the attack
-- ============================================
CREATE TABLE affected_services (
    service_id INT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    ip_address VARCHAR(15) NOT NULL,
    port INT NOT NULL,
    criticality INT NOT NULL CHECK (criticality BETWEEN 1 AND 5),
    dependencies VARCHAR(100),
    owner_team VARCHAR(100) NOT NULL,
    recovery_time_objective INT NOT NULL COMMENT 'Minutes',
    status ENUM('ONLINE', 'OFFLINE', 'DEGRADED') DEFAULT 'ONLINE',
    INDEX idx_criticality (criticality),
    INDEX idx_service_type (service_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: ip_intelligence
-- Purpose: Threat intelligence data for attacker IP addresses
-- ============================================
CREATE TABLE ip_intelligence (
    ip_address VARCHAR(15) PRIMARY KEY,
    country_code CHAR(2) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    city VARCHAR(100),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    isp VARCHAR(200),
    asn VARCHAR(20),
    organization VARCHAR(200),
    is_tor BOOLEAN DEFAULT FALSE,
    is_vpn BOOLEAN DEFAULT FALSE,
    is_proxy BOOLEAN DEFAULT FALSE,
    is_hosting BOOLEAN DEFAULT FALSE,
    threat_score INT NOT NULL CHECK (threat_score BETWEEN 0 AND 100),
    threat_category ENUM('LOW_CONFIDENCE', 'SUSPICIOUS', 'KNOWN_ATTACKER', 'APT_SUSPECTED') NOT NULL,
    first_seen DATETIME(3) NOT NULL,
    last_seen DATETIME(3) NOT NULL,
    total_reports INT DEFAULT 0,
    INDEX idx_country (country_code),
    INDEX idx_threat_score (threat_score),
    INDEX idx_threat_category (threat_category),
    INDEX idx_tor (is_tor),
    INDEX idx_vpn (is_vpn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: attack_logs
-- Purpose: Individual attack event records
-- ============================================
CREATE TABLE attack_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    timestamp DATETIME(3) NOT NULL,
    source_ip VARCHAR(15) NOT NULL,
    source_port INT NOT NULL,
    destination_ip VARCHAR(15) NOT NULL,
    destination_port INT NOT NULL,
    protocol ENUM('TCP', 'UDP', 'HTTP', 'HTTPS') NOT NULL,
    attack_type ENUM('DDOS_SYN_FLOOD', 'DDOS_UDP_FLOOD', 'SQL_INJECTION', 'BRUTE_FORCE', 'XSS_ATTEMPT') NOT NULL,
    attack_subtype VARCHAR(50) NOT NULL,
    payload_hash CHAR(64) NOT NULL,
    payload_sample TEXT,
    bytes_sent INT NOT NULL,
    packets_count INT NOT NULL,
    severity ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
    blocked BOOLEAN NOT NULL,
    firewall_rule VARCHAR(50),
    target_service_id INT NOT NULL,
    INDEX idx_timestamp (timestamp),
    INDEX idx_source_ip (source_ip),
    INDEX idx_attack_type (attack_type),
    INDEX idx_severity (severity),
    INDEX idx_blocked (blocked),
    INDEX idx_target_service (target_service_id),
    INDEX idx_attack_time (attack_type, timestamp),
    INDEX idx_severity_blocked (severity, blocked),
    FOREIGN KEY (source_ip) REFERENCES ip_intelligence(ip_address),
    FOREIGN KEY (target_service_id) REFERENCES affected_services(service_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table: incident_timeline
-- Purpose: High-level incident response events
-- ============================================
CREATE TABLE incident_timeline (
    event_id INT PRIMARY KEY AUTO_INCREMENT,
    timestamp DATETIME(3) NOT NULL,
    event_type ENUM('DETECTION', 'ALERT', 'ESCALATION', 'ANALYSIS', 'MITIGATION', 'CONTAINMENT', 'RECOVERY', 'CLOSURE', 'BREACH') NOT NULL,
    description TEXT NOT NULL,
    severity ENUM('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') NOT NULL,
    reported_by VARCHAR(100) NOT NULL,
    action_taken TEXT,
    INDEX idx_timestamp (timestamp),
    INDEX idx_event_type (event_type),
    INDEX idx_severity (severity)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Views for Common Analyses
-- ============================================

-- View: Attack summary by type and severity
CREATE OR REPLACE VIEW v_attack_summary AS
SELECT 
    attack_type,
    severity,
    COUNT(*) as total_attacks,
    SUM(blocked) as blocked_count,
    SUM(CASE WHEN blocked = 0 THEN 1 ELSE 0 END) as successful_attacks,
    ROUND(SUM(blocked) * 100.0 / COUNT(*), 2) as block_rate_pct,
    AVG(bytes_sent) as avg_bytes,
    SUM(packets_count) as total_packets
FROM attack_logs
GROUP BY attack_type, severity;

-- View: Geographic attack distribution
CREATE OR REPLACE VIEW v_geo_distribution AS
SELECT 
    i.country_code,
    i.country_name,
    COUNT(DISTINCT i.ip_address) as unique_attackers,
    COUNT(l.log_id) as total_attacks,
    SUM(CASE WHEN i.is_tor THEN 1 ELSE 0 END) as tor_attacks,
    SUM(CASE WHEN i.is_vpn THEN 1 ELSE 0 END) as vpn_attacks,
    AVG(i.threat_score) as avg_threat_score
FROM ip_intelligence i
JOIN attack_logs l ON i.ip_address = l.source_ip
GROUP BY i.country_code, i.country_name
ORDER BY total_attacks DESC;

-- View: Service targeting analysis
CREATE OR REPLACE VIEW v_service_targeting AS
SELECT 
    s.service_id,
    s.service_name,
    s.criticality,
    COUNT(l.log_id) as total_attacks,
    SUM(CASE WHEN l.severity = 'CRITICAL' THEN 1 ELSE 0 END) as critical_attacks,
    SUM(CASE WHEN l.blocked = 0 THEN 1 ELSE 0 END) as successful_attacks,
    ROUND(SUM(l.blocked) * 100.0 / COUNT(*), 2) as block_rate_pct
FROM affected_services s
LEFT JOIN attack_logs l ON s.service_id = l.target_service_id
GROUP BY s.service_id, s.service_name, s.criticality
ORDER BY total_attacks DESC;

-- View: Attack timeline (5-minute buckets)
CREATE OR REPLACE VIEW v_attack_timeline AS
SELECT 
    DATE_FORMAT(timestamp, '%Y-%m-%d %H:%i:00') as time_bucket,
    attack_type,
    COUNT(*) as attack_count,
    SUM(CASE WHEN blocked = 0 THEN 1 ELSE 0 END) as successful_count
FROM attack_logs
GROUP BY time_bucket, attack_type
ORDER BY time_bucket, attack_type;
