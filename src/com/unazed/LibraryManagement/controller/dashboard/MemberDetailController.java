package com.unazed.LibraryManagement.controller.dashboard;

import java.util.logging.Logger;

import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.User;

import javafx.fxml.FXML;
import javafx.scene.control.CheckBox;

@ViewController.ViewName(View.DASHBOARD_VIEW_MEMBERS_DETAIL)
@ViewController.AllowedRoles({User.Role.Librarian})
public class MemberDetailController extends ViewController.UserAwareController
{
  private static final Logger logger = Logger.getLogger(
    MemberDetailController.class.getName());

  @FXML private CheckBox cbModifyUser;

  @FXML
  private void initialize()
  {
  } 

  @FXML
  private void onMemberDetailModifyToggle()
  {
    boolean modifyEnabled = cbModifyUser.isSelected();
    logger.info("Modify user toggled: " + (modifyEnabled ? "enabled" : "disabled"));
  }

  @FXML
  private void onMemberDetailSaved()
  {
    logger.info("Saving member details - not implemented yet");
  }
}
