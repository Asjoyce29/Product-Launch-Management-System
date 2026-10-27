import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Product Launch Management System (PLMS) - Backend REST API Service
 * Author: Joyce Blessinah S (25BCE2979)
 * Institution: VIT Vellore
 */
public class Server {
    static final String DB_URL = "jdbc:mysql://localhost:3306/productlaunchms?useSSL=false&allowPublicKeyRetrieval=true";
    static final String DB_USER = "root";
    static final String DB_PASS = "12345678";

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);

        // Core API Endpoints
        server.createContext("/api/products", new ProductHandler());
        server.createContext("/api/events", new EventHandler());
        server.createContext("/api/attendees", new AttendeeHandler());
        server.createContext("/api/stats", new StatsHandler());

        server.setExecutor(null);
        System.out.println("========================================================");
        System.out.println("🚀 PLMS Java Microservice running at http://localhost:8080");
        System.out.println("   - Products API:   http://localhost:8080/api/products");
        System.out.println("   - Events API:     http://localhost:8080/api/events");
        System.out.println("   - Attendees API:  http://localhost:8080/api/attendees");
        System.out.println("   - System Stats:   http://localhost:8080/api/stats");
        System.out.println("========================================================");
        server.start();
    }

    // Helper: Add standard CORS headers
    static void setCorsHeaders(HttpExchange exchange) {
        exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
        exchange.getResponseHeaders().set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS");
        exchange.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type, Authorization");
    }

    // Helper: Send JSON response
    static void sendJsonResponse(HttpExchange exchange, int statusCode, String jsonResponse) {
        try {
            setCorsHeaders(exchange);
            byte[] bytes = jsonResponse.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json; charset=UTF-8");
            exchange.sendResponseHeaders(statusCode, bytes.length);
            OutputStream os = exchange.getResponseBody();
            os.write(bytes);
            os.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // Helper: Read request body as String
    static String readRequestBody(HttpExchange exchange) {
        try (InputStream is = exchange.getRequestBody();
             BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line);
            }
            return sb.toString();
        } catch (Exception e) {
            return "";
        }
    }

    // Helper: Extract JSON value via Regex
    static String extractJsonField(String json, String field) {
        Pattern pattern = Pattern.compile("\"" + field + "\"\\s*:\\s*(\"[^\"]*\"|\\d+(?:\\.\\d+)?|true|false|null)");
        Matcher matcher = pattern.matcher(json);
        if (matcher.find()) {
            String val = matcher.group(1).trim();
            if (val.startsWith("\"") && val.endsWith("\"")) {
                return val.substring(1, val.length() - 1);
            }
            return val;
        }
        return null;
    }

    // =========================================================================
    // 1. PRODUCT HANDLER (GET, POST, DELETE)
    // =========================================================================
    static class ProductHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) {
            setCorsHeaders(exchange);
            String method = exchange.getRequestMethod();

            if ("OPTIONS".equalsIgnoreCase(method)) {
                sendJsonResponse(exchange, 204, "");
                return;
            }

            try {
                if ("GET".equalsIgnoreCase(method)) {
                    // Fetch all products from MySQL
                    try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                         Statement stmt = con.createStatement();
                         ResultSet rs = stmt.executeQuery("SELECT * FROM PRODUCT ORDER BY Product_ID ASC")) {

                        StringBuilder json = new StringBuilder("[");
                        boolean first = true;
                        while (rs.next()) {
                            if (!first) json.append(",");
                            json.append("{")
                                .append("\"id\":").append(rs.getInt("Product_ID")).append(",")
                                .append("\"skinType\":\"").append(escapeJson(rs.getString("Skin_Type"))).append("\",")
                                .append("\"category\":\"").append(escapeJson(rs.getString("Category"))).append("\",")
                                .append("\"price\":").append(rs.getDouble("Price")).append(",")
                                .append("\"shelfLife\":").append(rs.getInt("Shelf_Life")).append(",")
                                .append("\"stock\":").append(rs.getInt("Stock_Quantity"))
                                .append("}");
                            first = false;
                        }
                        json.append("]");
                        sendJsonResponse(exchange, 200, json.toString());
                    }
                } 
                else if ("POST".equalsIgnoreCase(method)) {
                    // Insert new product into MySQL
                    String body = readRequestBody(exchange);
                    String idStr = extractJsonField(body, "id");
                    String skinType = extractJsonField(body, "skinType");
                    String category = extractJsonField(body, "category");
                    String priceStr = extractJsonField(body, "price");
                    String shelfLifeStr = extractJsonField(body, "shelfLife");
                    String stockStr = extractJsonField(body, "stock");

                    if (idStr == null || skinType == null || category == null || priceStr == null) {
                        sendJsonResponse(exchange, 400, "{\"error\":\"Missing required fields: id, skinType, category, price\"}");
                        return;
                    }

                    int id = Integer.parseInt(idStr);
                    double price = Double.parseDouble(priceStr);
                    int shelfLife = shelfLifeStr != null ? Integer.parseInt(shelfLifeStr) : 24;
                    int stock = stockStr != null ? Integer.parseInt(stockStr) : 500;

                    try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                         PreparedStatement ps = con.prepareStatement(
                             "INSERT INTO PRODUCT (Product_ID, Skin_Type, Category, Price, Shelf_Life, Stock_Quantity) " +
                             "VALUES (?, ?, ?, ?, ?, ?) " +
                             "ON DUPLICATE KEY UPDATE Skin_Type=?, Category=?, Price=?, Shelf_Life=?, Stock_Quantity=?")) {
                        ps.setInt(1, id);
                        ps.setString(2, skinType);
                        ps.setString(3, category);
                        ps.setDouble(4, price);
                        ps.setInt(5, shelfLife);
                        ps.setInt(6, stock);

                        ps.setString(7, skinType);
                        ps.setString(8, category);
                        ps.setDouble(9, price);
                        ps.setInt(10, shelfLife);
                        ps.setInt(11, stock);

                        ps.executeUpdate();
                        sendJsonResponse(exchange, 201, "{\"success\":true,\"message\":\"Product saved to MySQL\",\"id\":" + id + "}");
                    }
                } 
                else if ("DELETE".equalsIgnoreCase(method)) {
                    // Delete product by query string: /api/products?id=301
                    String query = exchange.getRequestURI().getQuery();
                    if (query != null && query.contains("id=")) {
                        String idStr = query.replace("id=", "").trim();
                        int id = Integer.parseInt(idStr);

                        try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                             PreparedStatement ps = con.prepareStatement("DELETE FROM PRODUCT WHERE Product_ID = ?")) {
                            ps.setInt(1, id);
                            int rows = ps.executeUpdate();
                            if (rows > 0) {
                                sendJsonResponse(exchange, 200, "{\"success\":true,\"message\":\"Product deleted from MySQL\"}");
                            } else {
                                sendJsonResponse(exchange, 404, "{\"error\":\"Product not found\"}");
                            }
                        }
                    } else {
                        sendJsonResponse(exchange, 400, "{\"error\":\"Query parameter 'id' required\"}");
                    }
                } 
                else {
                    sendJsonResponse(exchange, 405, "{\"error\":\"Method Not Allowed\"}");
                }
            } catch (Exception e) {
                e.printStackTrace();
                sendJsonResponse(exchange, 500, "{\"error\":\"Database Error: " + escapeJson(e.getMessage()) + "\"}");
            }
        }
    }

    // =========================================================================
    // 2. EVENT HANDLER (GET)
    // =========================================================================
    static class EventHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) {
            setCorsHeaders(exchange);
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, "");
                return;
            }

            try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                 Statement stmt = con.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT * FROM EVENT ORDER BY Event_Date ASC")) {

                StringBuilder json = new StringBuilder("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    json.append("{")
                        .append("\"id\":").append(rs.getInt("Event_ID")).append(",")
                        .append("\"name\":\"").append(escapeJson(rs.getString("Event_Name"))).append("\",")
                        .append("\"date\":\"").append(rs.getDate("Event_Date")).append("\",")
                        .append("\"time\":\"").append(rs.getTime("Start_Time")).append("\",")
                        .append("\"building\":\"").append(escapeJson(rs.getString("Building_Name"))).append("\",")
                        .append("\"street\":\"").append(escapeJson(rs.getString("Street"))).append("\",")
                        .append("\"city\":\"").append(escapeJson(rs.getString("City"))).append("\",")
                        .append("\"capacity\":").append(rs.getInt("Venue_Capacity"))
                        .append("}");
                    first = false;
                }
                json.append("]");
                sendJsonResponse(exchange, 200, json.toString());
            } catch (Exception e) {
                e.printStackTrace();
                sendJsonResponse(exchange, 500, "{\"error\":\"Failed to fetch events: " + escapeJson(e.getMessage()) + "\"}");
            }
        }
    }

    // =========================================================================
    // 3. ATTENDEE & ROSTER HANDLER (GET)
    // =========================================================================
    static class AttendeeHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) {
            setCorsHeaders(exchange);
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, "");
                return;
            }

            try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                 Statement stmt = con.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT * FROM vw_EventAttendeeRoster LIMIT 50")) {

                StringBuilder json = new StringBuilder("[");
                boolean first = true;
                while (rs.next()) {
                    if (!first) json.append(",");
                    json.append("{")
                        .append("\"personId\":").append(rs.getInt("Person_ID")).append(",")
                        .append("\"name\":\"").append(escapeJson(rs.getString("Full_Name"))).append("\",")
                        .append("\"email\":\"").append(escapeJson(rs.getString("Email"))).append("\",")
                        .append("\"role\":\"").append(escapeJson(rs.getString("Present_As"))).append("\",")
                        .append("\"passType\":\"").append(escapeJson(rs.getString("Pass_Type"))).append("\",")
                        .append("\"status\":\"").append(escapeJson(rs.getString("Attendance_Status"))).append("\",")
                        .append("\"diet\":\"").append(escapeJson(rs.getString("Dietary_Restriction"))).append("\",")
                        .append("\"eventName\":\"").append(escapeJson(rs.getString("Event_Name"))).append("\"")
                        .append("}");
                    first = false;
                }
                json.append("]");
                sendJsonResponse(exchange, 200, json.toString());
            } catch (Exception e) {
                e.printStackTrace();
                sendJsonResponse(exchange, 500, "{\"error\":\"Failed to fetch attendees: " + escapeJson(e.getMessage()) + "\"}");
            }
        }
    }

    // =========================================================================
    // 4. STATS HANDLER (GET) - Aggregate metrics across tables
    // =========================================================================
    static class StatsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) {
            setCorsHeaders(exchange);
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                sendJsonResponse(exchange, 204, "");
                return;
            }

            try (Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                 Statement stmt = con.createStatement()) {

                int totalProducts = 0;
                int totalEvents = 0;
                int totalAttendees = 0;
                double avgRating = 4.8;

                ResultSet rs1 = stmt.executeQuery("SELECT COUNT(*) FROM PRODUCT");
                if (rs1.next()) totalProducts = rs1.getInt(1);
                rs1.close();

                ResultSet rs2 = stmt.executeQuery("SELECT COUNT(*) FROM EVENT");
                if (rs2.next()) totalEvents = rs2.getInt(1);
                rs2.close();

                ResultSet rs3 = stmt.executeQuery("SELECT COUNT(*) FROM EVENT_REGISTRATION");
                if (rs3.next()) totalAttendees = rs3.getInt(1);
                rs3.close();

                ResultSet rs4 = stmt.executeQuery("SELECT COALESCE(ROUND(AVG(Rating), 2), 4.8) FROM FEEDBACK_REVIEW");
                if (rs4.next()) avgRating = rs4.getDouble(1);
                rs4.close();

                String json = "{"
                    + "\"totalProducts\":" + totalProducts + ","
                    + "\"totalEvents\":" + totalEvents + ","
                    + "\"totalAttendees\":" + totalAttendees + ","
                    + "\"averageRating\":" + avgRating + ","
                    + "\"dbStatus\":\"CONNECTED\","
                    + "\"campus\":\"VIT Vellore\""
                    + "}";
                sendJsonResponse(exchange, 200, json);
            } catch (Exception e) {
                e.printStackTrace();
                sendJsonResponse(exchange, 500, "{\"error\":\"Database stats error: " + escapeJson(e.getMessage()) + "\"}");
            }
        }
    }

    static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}