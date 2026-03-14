package com.unazed.LibraryManagement;

import javafx.application.Application;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.stage.Stage;
import java.util.logging.Logger;
import java.sql.SQLException;
import java.util.logging.Level;

public class LibraryManagement extends Application
{
  private static final Logger logger = Logger.getLogger(
    LibraryManagement.class.getName());
  private SqlInterface sqlInterface;

  @Override
  public void start(Stage stage)
  {
    try
    {
      sqlInterface = new SqlInterface("jdbc:postgresql://localhost/?user=postgres&password=postgres");
    } catch (SQLException sqlExc)
    {
      Alert alert = new Alert(AlertType.ERROR);
      alert.setTitle("Connection Error");
      alert.setHeaderText("Failed to connect to database");
      alert.setContentText(
	"Check that the library database is running and try again");
      alert.showAndWait();
      return;
    }
    logger.info("Showing window");
    stage.show();
  }

  public static void main(String[] args)
  {
    launch();
  }
}
