package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.ResourceLoader;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.model.User;
import com.unazed.LibraryManagement.model.User.UserAware;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.SplitPane;
import javafx.scene.layout.StackPane;

public class MainController
{
  @FXML private StackPane contentPane;
  @FXML private SplitPane mainSplitPane;
  @FXML private StackPane menuPane;

  private static final java.util.logging.Logger logger
    = Logger.getLogger(MainController.class.getName());
  private User authenticatedUser;
  public static final View VIEW = View.MAIN;

  @FXML
  public void initialize()
  {
    EventBus bus = EventBus.get();

    bus.subscribe(Events.ViewSwitchEvent.class, e -> switchTo(e.getView()));

    bus.subscribe(
      Events.UserAuthenticatedEvent.class,
      e -> {
        if (authenticatedUser != null)
          throw new IllegalStateException("User is already authenticated");
        authenticatedUser = e.getUser();
        switchTo(DashboardController.VIEW);
      }
    );

    bus.subscribe(
      Events.AlertEvent.class,
      e -> {
        Alert alert = new Alert(AlertType.ERROR);
        alert.setTitle(e.getTitle());
        alert.setHeaderText(e.getHeader());
        alert.setContentText(e.getContent());
        alert.showAndWait();
      }
    );

    switchTo(LoginController.VIEW);
  }

  /* change menu tab fx:id = AuthMenu to another file */
  private void switchMenuTabTo(View view)
  {
    logger.info("Switching menu tab: " + view);
    switch (view)
    {
      case LOGIN, REGISTER
      -> {
        try
        {
          Parent menu = ResourceLoader.loadFxml(AuthMenuController.VIEW);
          menuPane.getChildren().setAll(menu);
        } catch (IOException ioExc)
        {
          EventBus.get().publish(
            new Events.AlertEvent(AlertType.ERROR, "resource.error"));
          throw new RuntimeException(ioExc);
        }
      }
      case DASHBOARD
      -> {
        try
        {
          Parent menu = ResourceLoader.loadFxml(AppMenuController.VIEW);
          menuPane.getChildren().setAll(menu);
        } catch (IOException ioExc)
        {
          EventBus.get().publish(
            new Events.AlertEvent(AlertType.ERROR, "resource.error"));
          throw new RuntimeException(ioExc);
        }
      }
      default -> logger.log(Level.WARNING, "No menu tab for view: " + view);
    }
  }

  private void switchTo(View view)
  {
    logger.info("Switching view: " + view);
    try
    {
      FXMLLoader loader = new FXMLLoader(ResourceLoader.getFxmlUrl(view));
      Object controller = loader.getController();
      if (controller instanceof UserAware)
        ((UserAware) controller).setUser(authenticatedUser);

      /* Our primary window consists of a 3-pane layout; authentication forms
       * only use the middle pane, however post-auth. forms may use more than
       * one pane.
       */
      Parent root = loader.load();
      logger.info(root.getClass().getName());
      if (root instanceof SplitPane)
        mainSplitPane.getItems().setAll(root);
      else
        contentPane.getChildren().setAll(root);
      switchMenuTabTo(view);
    } catch (IOException ioExc)
    {
      EventBus.get().publish(
        new Events.AlertEvent(AlertType.ERROR, "resource.error"));
      throw new RuntimeException(ioExc);
    }
  }
}
