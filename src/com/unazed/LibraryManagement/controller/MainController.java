package com.unazed.LibraryManagement.controller;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.ResourceLoader;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.model.User;
import com.unazed.LibraryManagement.model.User.UserAware;

import java.io.IOException;
import java.util.logging.Logger;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.control.SplitPane;
import javafx.scene.layout.StackPane;

public class MainController
{
  @FXML private AuthMenuController authMenuController;
  @FXML private StackPane contentPane;
  @FXML private SplitPane mainSplitPane;

  private static final java.util.logging.Logger logger
    = Logger.getLogger(MainController.class.getName());
  private User authenticatedUser;
  public static final View VIEW = View.MAIN;

  @FXML
  public void initialize()
  {
    EventBus bus = EventBus.get();
    bus.subscribe(Events.ViewSwitchEvent.class, e -> switchTo(e.getView()));
    bus.subscribe(Events.UserAuthenticatedEvent.class, e -> {
      if (authenticatedUser != null)
        throw new IllegalStateException("User is already authenticated");
      authenticatedUser = e.getUser();
      switchTo(DashboardController.VIEW);
    });

    switchTo(LoginController.VIEW);
  }

  private void switchTo(View view)
  {
    logger.info("Switching view: " + view);
    try
    {
      FXMLLoader loader = new FXMLLoader(ResourceLoader.getFxmlUrl(view));
      Object controller = loader.getController();
      if (controller instanceof UserAware)
      {
        ((UserAware) controller).setUser(authenticatedUser);
      }

      /* Our primary window consists of a 3-pane layout; authentication forms
       * only use the middle pane, however post-auth. forms may use more than
       * one pane.
       */
      Parent root = loader.load();
      if (root instanceof SplitPane)
      {
        mainSplitPane.getItems().setAll(root);
      }
      else
      {
        contentPane.getChildren().setAll(root);
      }
    } catch (IOException _) { return; }
  }
}
