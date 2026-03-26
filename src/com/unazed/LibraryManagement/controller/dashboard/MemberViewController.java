package com.unazed.LibraryManagement.controller.dashboard;

import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.model.User;
import com.unazed.LibraryManagement.ViewController;

import javafx.fxml.FXML;
import javafx.scene.control.ListView;

@ViewController.ViewName(View.DASHBOARD_VIEW_MEMBERS)
@ViewController.AllowedRoles({User.Role.Librarian})
public class MemberViewController extends ViewController.UserAwareController
{
  @FXML private ListView<String> dashboardMemberListView;

  public View getViewName()
  {
    return View.DASHBOARD_VIEW_MEMBERS;
  }

  @FXML
  public void initialize()
  {
    dashboardMemberListView.getItems().setAll("a", "b", "c");
  } 

  @Override
  public void whenUserAvailable(User user)
  {
  }
}
