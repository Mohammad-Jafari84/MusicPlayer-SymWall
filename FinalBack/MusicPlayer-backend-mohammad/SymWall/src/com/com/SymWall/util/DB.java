/*package com.com.SymWall.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB {
    private static final String URL = "jdbc:mysql://localhost:3306/symwall";
    private static final String USER = "root";
    private static final String PASS = "Mm442140666113842005";

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }
}

*/
package com.com.SymWall.util;

        import java.sql.Connection;
        import java.sql.DriverManager;
        import java.sql.SQLException;

public class DB {

    private static final String URL = "jdbc:mysql://localhost:3306/music_db";
    private static final String USER = "root";
    private static final String PASS = "6696";

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }

    public static void main(String[] args) {
        try (Connection conn = getConnection()) {
            if (conn != null) {
                System.out.println("✅ اتصال به دیتابیس با موفقیت برقرار شد!");
            }
        } catch (SQLException e) {
            System.err.println("❌ اتصال به دیتابیس شکست خورد:");
            e.printStackTrace();
        }
    }
}

