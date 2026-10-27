import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;

import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.sql.*;

public class Server {
    // MySQL Database connection settings
    static final String DB_URL = "jdbc:mysql://localhost:3306/productlaunchms";
    static final String DB_USER = "root";
    static final String DB_PASS = "12345678";

    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        
        // Setup API endpoint to retrieve skincare products[cite: 16]
        server.createContext("/api/products", new ProductHandler());
        
        server.setExecutor(null);
        System.out.println("🚀 Java Server running at http://localhost:8080/api/products");
        server.start();
    }

    static class ProductHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) {
            try {
                // Allow web browser access (CORS)
                exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
                exchange.getResponseHeaders().add("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
                exchange.getResponseHeaders().add("Access-Control-Allow-Headers", "Content-Type");

                if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                    exchange.sendResponseHeaders(204, -1);
                    return;
                }

                if ("GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                    Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                    Statement stmt = con.createStatement();
                    ResultSet rs = stmt.executeQuery("SELECT * FROM PRODUCT");

                    StringBuilder json = new StringBuilder("[");
                    boolean first = true;
                    while (rs.next()) {
                        if (!first) json.append(",");
                        json.append("{")
                            .append("\"id\":").append(rs.getInt("Product_ID")).append(",")
                            .append("\"skinType\":\"").append(rs.getString("Skin_Type")).append("\",")
                            .append("\"category\":\"").append(rs.getString("Category")).append("\",")
                            .append("\"price\":").append(rs.getDouble("Price"))
                            .append("}");
                        first = false;
                    }
                    json.append("]");
                    rs.close();
                    stmt.close();
                    con.close();

                    byte[] response = json.toString().getBytes();
                    exchange.getResponseHeaders().set("Content-Type", "application/json");
                    exchange.sendResponseHeaders(200, response.length);
                    OutputStream os = exchange.getResponseBody();
                    os.write(response);
                    os.close();
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}