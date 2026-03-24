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

import javafx.event.Event;
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
  public static final View VIEW = View.MAIN;

  private User authenticatedUser;
  private EventBus eventBus = EventBus.get();

  @FXML
  public void initialize()
  {
    eventBus.subscribe(
      Events.ViewSwitchEvent.class, e -> switchTo(e.getView()));
    eventBus.subscribe(
      Events.UserAuthenticatedEvent.class, this::userAuthenticatedEventHandler);
    eventBus.subscribe(Events.AlertEvent.class, this::alertEventHandler);
    eventBus.subscribe(
      Events.UserSignoutEvent.class, this::userSignoutEventHandler);

    switchTo(LoginController.VIEW);
  }

  private void userSignoutEventHandler(Events.UserSignoutEvent event)
  {
    if (authenticatedUser == null)
      throw new IllegalStateException("No user is currently authenticated");
    logger.info("User signed out: " + authenticatedUser.getUsername());
    eventBus.publish(new Events.StatusMessageEvent("Signed out successfully."));
    authenticatedUser = null;
    switchTo(LoginController.VIEW);
  }

  private void alertEventHandler(Events.AlertEvent event)
  {
    Alert alert = new Alert(event.getType());
    alert.setTitle(event.getTitle());
    alert.setHeaderText(event.getHeader());
    alert.setContentText(event.getContent());
    alert.showAndWait();
  }

  private void userAuthenticatedEventHandler(
    Events.UserAuthenticatedEvent event)
  {
    if (authenticatedUser != null)
      throw new IllegalStateException("User is already authenticated");
    authenticatedUser = event.getUser();
    switchTo(DashboardController.VIEW);
    switchMenuTabTo(LoginController.VIEW);
  }

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
          eventBus.publish(
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
          eventBus.publish(
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
      Parent root = loader.load();

      Object controller = loader.getController();
      if (controller instanceof UserAware)
      {
        UserAware userAwareController = (UserAware) controller;
        userAwareController.setBoundUser(authenticatedUser);
        userAwareController.whenUserAvailable(authenticatedUser);
      }

      if (!(root instanceof SplitPane))
        throw new IllegalStateException(
          "Root node of view FXML must be a SplitPane");

      mainSplitPane.getItems().setAll(root);
      switchMenuTabTo(view);
    } catch (IOException ioExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "resource.error"));
      throw new RuntimeException(ioExc);
    }
  }
}
