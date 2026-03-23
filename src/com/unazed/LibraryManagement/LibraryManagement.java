package com.unazed.LibraryManagement;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.stage.Stage;
import java.util.logging.Logger;
import java.io.IOException;
import java.net.URL;
import java.sql.SQLException;
import java.util.logging.Level;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;

public class LibraryManagement extends Application
{
  private static final Logger logger = Logger.getLogger(
    LibraryManagement.class.getName());
  private SqlInterface sqlInterface;

  public void showError(String title, String header, String content)
  {
    Alert alert = new Alert(AlertType.ERROR);
    alert.setTitle(title);
    alert.setHeaderText(header);
    alert.setContentText(content);
    alert.showAndWait();
  }

  @Override
  public void start(Stage stage)
  {
    try
    {
      sqlInterface = new SqlInterface(
        "jdbc:postgresql://localhost/library_main?user=app_user&password=app_user");
    } catch (SQLException sqlExc)
    {
      logger.log(Level.SEVERE,
        "Failed to connect to SQL server: " + sqlExc.getMessage());
      showError("Database Connection Error",
        "Failed to connect to the database",
        "Check that the database server is running and try again");
      return;
    }

    URL mainFxmlUrl = getClass().getResource("/views/Main.fxml");
    if (mainFxmlUrl == null)
    {
      logger.log(Level.SEVERE, "Failed to find Main.fxml in resources");
      showError("Resource Error",
        "Failed to load application resources",
        "Check that the application is properly installed and try again");
      return;
    }
    FXMLLoader loader = new FXMLLoader(mainFxmlUrl);
    Parent root;
    try
    {
      root = loader.load();
    } catch (IOException ioExc)
    {
      logger.log(Level.SEVERE, "Failed to load Main.fxml", ioExc);
      showError("Resource Error",
        "Failed to load application resources",
        "Check that the application is properly installed and try again");
      return;
    }

    stage.setScene(new Scene(root));
    stage.show();
  }

  public static void main(String[] args)
  {
    launch();
  }
}
