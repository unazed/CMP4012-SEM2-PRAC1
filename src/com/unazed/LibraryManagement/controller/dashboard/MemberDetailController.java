package com.unazed.LibraryManagement.controller.dashboard;

import java.util.List;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.LockableView;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.User;
import com.unazed.LibraryManagement.controller.DashboardController.DashboardEvents.AuxDataReceiver;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBox;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;

@ViewController.ViewName(View.DASHBOARD_VIEW_MEMBERS_DETAIL)
@ViewController.AllowedRoles({User.Role.Librarian})
public class MemberDetailController
  extends ViewController.UserAwareController
  implements AuxDataReceiver<User>
{
  private static final Logger logger = Logger.getLogger(
    MemberDetailController.class.getName());
  private final LockableView lockableView = new LockableView();

  @FXML private CheckBox cbModifyUser;
  @FXML private TextField tfEmail;
  @FXML private TextField tfUsername;
  @FXML private ComboBox<String> cbAccountStatus;
  @FXML private ListView<String> lvMemberDetailLoans;
  @FXML private Button btnSaveChanges;

  @FXML
  private void initialize()
  {
    lockableView.lockableElements = List.of(
      tfEmail, tfUsername, cbAccountStatus, btnSaveChanges);
    lockableView.lockView();
  } 

  @FXML
  private void onMemberDetailModifyToggle()
  {
    boolean modifyEnabled = cbModifyUser.isSelected();
    if (modifyEnabled)
      lockableView.unlockView();
    else
      lockableView.lockView();
  }

  @FXML
  private void onMemberDetailSaved()
  {
    logger.info("Saving member details - not implemented yet");
  }

  @Override
  public void receiveAuxData(User data)
  {
    tfEmail.setText(data.getEmail());
    tfUsername.setText(data.getUsername());
    
  }
}
