package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;

import java.io.IOException;
import java.net.URL;
import java.util.logging.Level;
import java.util.logging.Logger;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.layout.StackPane;

public class MainController
{
  @FXML private AuthMenuController authMenuController;
  @FXML private StackPane contentPane;

  private static final java.util.logging.Logger logger
    = Logger.getLogger(MainController.class.getName());

  @FXML
  public void initialize()
  {
    EventBus.get().subscribe(
      Events.ViewSwitchEvent.class, e -> switchTo(e.getView()));

    switchTo("Login");
  }

  private void switchTo(String view)
  {
    try
    {
      URL fxml = getClass().getResource("/views/" + view + ".fxml");
      Parent root = FXMLLoader.load(fxml);
      contentPane.getChildren().setAll(root);
    } catch (IOException e)
    {
      logger.log(Level.SEVERE, "Failed to load view: " + view, e);
    }
  }
}
