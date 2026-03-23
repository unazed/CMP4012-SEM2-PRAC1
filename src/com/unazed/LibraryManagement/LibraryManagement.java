package com.unazed.LibraryManagement;

import com.unazed.LibraryManagement.controller.MainController;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.stage.Stage;
import java.util.logging.Logger;
import java.io.IOException;
import java.sql.SQLException;

public class LibraryManagement extends Application
{
  private static final Logger logger = Logger.getLogger(
    LibraryManagement.class.getName());

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
      SqlInterface.newInstance(
        "jdbc:postgresql://localhost/library_main?user=app_user&password=app_user");
    } catch (SQLException sqlExc)
    {
      showError("Database Connection Error",
        "Failed to connect to the database",
        "Check that the database server is running and try again");
      return;
    }

    try
    {
      stage.setScene(new Scene(ResourceLoader.loadFxml(MainController.VIEW)));
      stage.show();
    } catch (IOException ioExc)
    {
      showError("Resource Loading Error",
        "Failed to load application resources",
        "Check that the application is properly installed and try again");
      return;
    }
  }

  public static void main(String[] args)
  {
    launch();
  }
}
