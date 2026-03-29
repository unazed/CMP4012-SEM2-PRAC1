package com.unazed.LibraryManagement.controller.dashboard;

import java.sql.SQLException;
import java.util.List;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.DatabaseFunctions;
import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.controller.DashboardController.DashboardEvents;
import com.unazed.LibraryManagement.model.gen.ResultType;
import com.unazed.LibraryManagement.model.gen.UserRole;
import com.unazed.LibraryManagement.model.gen.Users;

import javafx.fxml.FXML;
import javafx.scene.control.ListCell;
import javafx.scene.control.ListView;
import javafx.scene.control.Alert.AlertType;

@ViewController.ViewName(View.DASHBOARD_VIEW_MEMBERS)
@ViewController.AllowedRoles({UserRole.LIBRARIAN})
public class MemberViewController extends ViewController.UserAwareController
{
  private static final Logger logger = Logger.getLogger(
    MemberViewController.class.getName());
  private final EventBus eventBus = EventBus.get();

  @FXML private ListView<Users> dashboardMemberListView;

  @Override
  public void whenUserAvailable(String userToken)
  {
    logger.info("Loading members for dashboard view");
    try
    {
      ResultType result = DatabaseFunctions.getMembers(userToken);
      List<Users> memberList = result.getDataAsList(Users.class);
      if (memberList == null)
      {
        logger.info("No members found in database");
        return;
      }
      logger.info("Fetched " + memberList.size() + " members from database");
      dashboardMemberListView.getItems().addAll(memberList);
      dashboardMemberListView.setCellFactory(
        lv -> new ListCell<Users>()
        {
          @Override
          protected void updateItem(Users user, boolean empty)
          {
            super.updateItem(user, empty);
            setText(empty || user == null ? null : user.username());
          }
        }
      );
      dashboardMemberListView
        .getSelectionModel()
        .selectedItemProperty()
        .addListener(
          (_, _, selectedUser)
          -> eventBus.publish(new DashboardEvents.DashboardAuxSwapEvent<>(
              View.DASHBOARD_VIEW_MEMBERS_DETAIL, selectedUser)));
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.query.error"));
      throw new RuntimeException(
        "Failed to fetch members from database", sqlExc);
    }
  }
}
