package com.unazed.LibraryManagement.controller;

import java.util.List;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.model.User;

import javafx.fxml.FXML;

public class DashboardController extends User.UserAware
{
  private static final Logger logger = Logger.getLogger(
    DashboardController.class.getName());

  @FXML private javafx.scene.control.ListView<String> dashboardListView;
  @FXML private javafx.scene.control.Label lblUsername;

  public static final View VIEW = View.DASHBOARD;
  public static final List<String> menuItemsLibrarian = List.of(
    "Add/modify books",
    "View books",
    "View my loans",
    "View members",
    "View all loans");
  public static final List<String> menuItemsMember = List.of(
    "View books",
    "View my loans");

  @Override
  public final void whenUserAvailable(User user)
  {
    lblUsername.setText(getBoundUser().getUsername());
    if (getBoundUser().getRole() == User.Role.Librarian)
      dashboardListView.getItems().setAll(menuItemsLibrarian);
    else
      dashboardListView.getItems().setAll(menuItemsMember);
    dashboardListView
      .getSelectionModel()
      .selectedItemProperty()
      .addListener(
        (obs, oldVal, newVal)
        -> {
          if (newVal != null)
            onNavigationItemSelected(newVal);
        }
      );
  }

  @FXML
  private void onSignOutClick()
  {
    EventBus.get().publish(new Events.UserSignoutEvent());
  }

  private void onNavigationItemSelected(String item)
  {
    logger.info("Selected dashboard item: " + item);
  }
}
