package main;

import org.json.JSONObject;

import java.io.FileInputStream;
import java.io.InputStream;
import java.sql.*;
import java.util.Properties;
import java.util.TimeZone;

public class PasswordDB {
    public PasswordDB() { }

    public String evaluate() {
        String result = "";

        JSONObject resultSet = new JSONObject();

        try {
            ClassLoader classLoader = Thread.currentThread().getContextClassLoader();
            InputStream inputStream = classLoader.getResourceAsStream("oracleConfig.properties");
            Properties properties = new Properties();
            properties.load(inputStream);
            String url = properties.getProperty("url");
            String user = properties.getProperty("user");
            String password = properties.getProperty("password");

            TimeZone timeZone = TimeZone.getTimeZone("America/New_York");
            TimeZone.setDefault(timeZone);
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection conn = DriverManager.getConnection(url,user,password);
            Statement stmt = conn.createStatement();
            ResultSet rs;

            rs = stmt.executeQuery("SELECT STREET_ADDRESS, CITY, STATE_PROVINCE, POSTAL_CODE, COUNTRY_ID FROM HR.LOCATIONS ORDER BY COUNTRY_ID");
            while ( rs.next() ) {
                JSONObject row = new JSONObject();
                row.put("STREET_ADDRESS", rs.getString("STREET_ADDRESS"));
                row.put("CITY", rs.getString("CITY"));
                row.put("STATE_PROVINCE", rs.getString("STATE_PROVINCE"));
                row.put("POSTAL_CODE", rs.getString("POSTAL_CODE"));
                row.put("COUNTRY_ID", rs.getString("COUNTRY_ID"));
                resultSet.append("RESULT_SET", row);;
            }
            conn.close();
        } catch (Exception e) {
            result += "Got an exception!";
            result += e.getMessage();
        }
        result += resultSet.toString(4);
        return result;
    }
}