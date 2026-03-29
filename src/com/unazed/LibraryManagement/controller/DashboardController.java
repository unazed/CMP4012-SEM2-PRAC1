package com.unazed.LibraryManagement.controller;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.unazed.LibraryManagement.EventBus;
import com.unazed.LibraryManagement.Events;
import com.unazed.LibraryManagement.ResourceLoader;
import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.controller.DashboardController.DashboardEvents.AuxDataReceiver;
import com.unazed.LibraryManagement.controller.dashboard.MemberViewController;
import com.unazed.LibraryManagement.model.gen.UserRole;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.control.ScrollPane;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.Parent;
import javafx.scene.control.Label;
import javafx.scene.control.ListView;

@ViewController.ViewName(View.DASHBOARD)
@ViewController.AllowedRoles({UserRole.LIBRARIAN, UserRole.MEMBER})
public class DashboardController extends ViewController.UserAwareController
{
  public static class DashboardEvents
  {
    public static class DashboardContentSwapEvent
    {
      private final View newContentView;

      public DashboardContentSwapEvent(View newContentView)
      {
        this.newContentView = newContentView;
      }

      public View getNewContentView()
      {
        return newContentView;
      }      
    }

    public interface AuxDataReceiver<T>
    {
      void receiveAuxData(T auxData);
    }

    public static class DashboardAuxSwapEvent<T>
    {
      private final View newAuxView;
      private final T auxData;

      public DashboardAuxSwapEvent(View newAuxView, T auxData)
      {
        this.newAuxView = newAuxView;
        this.auxData = auxData;
      }

      public View getNewAuxView()
      {
        return newAuxView;
      }

      public T getAuxData()
      {
        return auxData;
      }
    }
  }

  private static final Logger logger = Logger.getLogger(
    DashboardController.class.getName());
  
  @FXML private ListView<String> dashboardListView;
  @FXML private Label lblUsername;
  @FXML private ScrollPane spDashboardContent;
  @FXML private ScrollPane spDashboardAux;
   
  private EventBus eventBus = EventBus.get();
  private Map<String, Class<? extends ViewController.UserAwareController>>
    menuItemControllerMap = Map.of(
      "View all members", MemberViewController.class);

  @Override
  public final void whenUserAvailable(String userToken)
  {
    for (
      Entry<String, Class<? extends ViewController.UserAwareController>> entry
      : menuItemControllerMap.entrySet())
    {
      ViewController.AllowedRoles annotation
        = entry.getValue().getAnnotation(ViewController.AllowedRoles.class);
      if (annotation == null)
        throw new IllegalStateException(
          "Controller class " + entry.getValue().getName()
          + " is missing @AllowedRoles annotation");
      if (List.of(annotation.value()).contains(getBoundUser().user_role()))
        dashboardListView.getItems().add(entry.getKey());
    }

    eventBus.subscribe(
      DashboardEvents.DashboardContentSwapEvent.class,
      e -> dashboardContentSwapEventHandler(e));
    eventBus.subscribe(
      DashboardEvents.DashboardAuxSwapEvent.class,
      e -> dashboardAuxSwapEventHandler(e));

    lblUsername.setText(getBoundUser().username());
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
    Class<? extends ViewController.UserAwareController> controllerClass
      = menuItemControllerMap.get(item);
    if (controllerClass == null)
      throw new IllegalStateException(
        "No controller mapped for menu item: " + item);
    eventBus.publish(new DashboardEvents.DashboardContentSwapEvent(
      ViewController.getViewOf(controllerClass)));
  }

  private void dashboardContentSwapEventHandler(
    DashboardEvents.DashboardContentSwapEvent event)
  {
    try
    {
      FXMLLoader loader = new FXMLLoader(
        ResourceLoader.getFxmlUrl(event.getNewContentView()));
      Parent root = loader.load();
      if (!(loader.getController()
        instanceof UserAwareController userAwareController))
      {
        throw new IllegalStateException(
          "Controller for view " + event.getNewContentView()
          + " does not extend UserAwareController");
      }
      userAwareController.setBoundUser(getBoundUser());
      userAwareController.whenUserAvailable(getBoundUserToken());
      spDashboardContent.setContent(root);
    } catch (IOException ioExc)
    {
      logger.log(Level.SEVERE, "Failed to swap dashboard content view", ioExc);
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "resource.error"));
      throw new RuntimeException(ioExc);
    }
  }

  @SuppressWarnings("unchecked")
  private void dashboardAuxSwapEventHandler(
    DashboardEvents.DashboardAuxSwapEvent<?> event)
  {
    try
    {
      FXMLLoader loader = new FXMLLoader(
        ResourceLoader.getFxmlUrl(event.getNewAuxView()));
      Parent root = loader.load();
      Object controller = loader.getController();
      if (controller instanceof UserAwareController userAwareController)
      {
        userAwareController.setBoundUser(getBoundUser());
        userAwareController.setBoundUserToken(getBoundUserToken());
        userAwareController.whenUserAvailable(getBoundUserToken()); 
      }

      if (controller instanceof AuxDataReceiver auxDataReceiver)
        auxDataReceiver.receiveAuxData(event.getAuxData());

      spDashboardAux.setContent(root);

    } catch (IOException ioExc)
    {
      logger.log(Level.SEVERE, "Failed to swap dashboard auxiliary view", ioExc);
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "resource.error"));
      throw new RuntimeException(ioExc);
    }
  }
}
