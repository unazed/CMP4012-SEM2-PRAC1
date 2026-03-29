package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.ResourceLoader;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.gen.UserRole;
import com.unazed.LibraryManagement.model.gen.Users;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.prefs.Preferences;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.control.Alert;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.SplitPane;
import javafx.scene.layout.StackPane;

@ViewController.ViewName(View.MAIN)
@ViewController.AllowedRoles({UserRole.LIBRARIAN, UserRole.MEMBER})
public class MainController extends ViewController
{
  @FXML private StackPane contentPane;
  @FXML private SplitPane mainSplitPane;
  @FXML private StackPane menuPane;

  private static final java.util.logging.Logger logger
    = Logger.getLogger(MainController.class.getName());

  private Users authenticatedUser;
  private String userToken;
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

    switchTo(View.LOGIN);
  }

  private void userSignoutEventHandler(Events.UserSignoutEvent event)
  {
    if (authenticatedUser == null)
      throw new IllegalStateException("No user is currently authenticated");
    logger.info("User signed out: " + authenticatedUser.username());
    eventBus.publish(new Events.StatusMessageEvent("Signed out successfully."));
    authenticatedUser = null;
    userToken = null;
    Preferences.userNodeForPackage(LoginController.class).remove("storedToken");
    switchTo(View.LOGIN);
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
    userToken = event.getUserToken();
    switchTo(View.DASHBOARD);
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
          Parent menu = ResourceLoader.loadFxml(View.AUTH_MENU);
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
          Parent menu = ResourceLoader.loadFxml(View.APP_MENU);
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

      if (!(controller instanceof ViewController viewController))
        throw new IllegalStateException(
          "Controller for view " + view + " does not extend ViewController");

      /* Solves the successful token login premature view switch */
      if (!viewController.postInitialize())
        return;

      if (viewController.getView() != view)
        throw new IllegalStateException(
          "Controller for view " + view + " has @ViewName " +
          viewController.getView());

      if (controller
        instanceof ViewController.UserAwareController userAwareController)
      {
        /* NB: Some controllers have an @AllowedRoles annotation specifying
         *     which user roles are allowed to access it.
         */
        if (!userAwareController.getAllowedRoles()
          .contains(authenticatedUser.user_role()))
        {
          eventBus.publish(
            new Events.AlertEvent(AlertType.ERROR, "access.denied"));
          return;
        }
        userAwareController.setBoundUser(authenticatedUser);
        userAwareController.setBoundUserToken(userToken);
        userAwareController.whenUserAvailable(userToken);
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
