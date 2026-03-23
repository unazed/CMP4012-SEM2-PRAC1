package com.unazed.LibraryManagement;

import com.unazed.LibraryManagement.controller.MainController;

import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.control.Alert.AlertType;
import javafx.stage.Stage;
import java.io.IOException;
import java.sql.SQLException;

public class LibraryManagement extends Application
{
  @Override
  public void start(Stage stage)
  {
    EventBus eventBus = EventBus.get();
    try
    {
      SqlInterface.newInstance(
        "jdbc:postgresql://localhost/library_main?user=app_user&password=app_user");
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      return;
    }

    try
    {
      stage.setScene(new Scene(ResourceLoader.loadFxml(MainController.VIEW)));
      stage.show();
    } catch (IOException ioExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "resource.error"));
      return;
    }
  }

  public static void main(String[] args)
  {
    launch();
  }
}
