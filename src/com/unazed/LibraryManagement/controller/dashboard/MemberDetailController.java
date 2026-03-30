package com.unazed.LibraryManagement.controller.dashboard;

import java.sql.SQLException;
import java.util.List;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.DatabaseFunctions;
import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.LockableView;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.controller.DashboardController.DashboardEvents.AuxDataReceiver;
import com.unazed.LibraryManagement.model.gen.ResultType;
import com.unazed.LibraryManagement.model.gen.UserRole;
import com.unazed.LibraryManagement.model.gen.UserStatus;
import com.unazed.LibraryManagement.model.gen.Users;

import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBox;
import javafx.scene.control.ListCell;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.scene.control.Alert.AlertType;

@ViewController.ViewName(View.DASHBOARD_VIEW_MEMBERS_DETAIL)
@ViewController.AllowedRoles({UserRole.LIBRARIAN})
public class MemberDetailController
  extends ViewController.UserAwareController
  implements AuxDataReceiver<Users>
{
  private static final Logger logger = Logger.getLogger(
    MemberDetailController.class.getName());
  private final LockableView lockableView = new LockableView();
  private final EventBus eventBus = EventBus.get();

  private Users selectedUser;

  @FXML private CheckBox cbModifyUser;
  @FXML private TextField tfEmail;
  @FXML private TextField tfUsername;
  @FXML private ComboBox<UserStatus> cbAccountStatus;
  @FXML private ListView<String> lvMemberDetailLoans;
  @FXML private Button btnSaveChanges;

  @FXML
  private void initialize()
  {
    lockableView.lockableElements = List.of(
      tfEmail, tfUsername, cbAccountStatus, btnSaveChanges);
    lockableView.lockView();
    cbAccountStatus.getItems().addAll(UserStatus.values());
    cbAccountStatus.setButtonCell(
      new ListCell<>()
      {
        @Override
        protected void updateItem(UserStatus item, boolean empty)
        {
          super.updateItem(item, empty);
          setText(empty || item == null ? null : item.value());
        }
      }
    );
    cbAccountStatus.setCellFactory(
      lv -> new ListCell<>()
      {
        @Override
        protected void updateItem(UserStatus item, boolean empty)
        {
          super.updateItem(item, empty);
          setText(empty || item == null ? null : item.value());
        }
      }
    );
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
    try
    {
      ResultType result = DatabaseFunctions.updateUserDetails(
        getBoundUserToken(), selectedUser.user_id(), tfEmail.getText(),
        tfUsername.getText(), cbAccountStatus.getValue());
      if (!result.success())
      {
        eventBus.publish(new Events.StatusMessageEvent(
          "Failed to update user details: " + result.errorCode()));
        return;
      }
      eventBus.publish(new Events.StatusMessageEvent("User details updated"));
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      throw new RuntimeException("Failed to update user details", sqlExc);
    }
  }

  @Override
  public void receiveAuxData(Users data)
  {
    tfEmail.setText(data.email());
    tfUsername.setText(data.username());
    cbAccountStatus.setValue(data.user_status());
    selectedUser = data;
  }
}
