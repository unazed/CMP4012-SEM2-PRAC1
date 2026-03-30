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
import com.unazed.LibraryManagement.controller.DashboardController.DashboardEvents;
import com.unazed.LibraryManagement.model.gen.Authors;
import com.unazed.LibraryManagement.model.gen.Books;
import com.unazed.LibraryManagement.model.gen.ResultType;
import com.unazed.LibraryManagement.model.gen.UserRole;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.collections.transformation.FilteredList;
import javafx.fxml.FXML;
import javafx.scene.control.Alert.AlertType;
import javafx.scene.control.CheckBox;
import javafx.scene.control.ComboBox;
import javafx.scene.control.DatePicker;
import javafx.scene.control.ListCell;
import javafx.scene.control.ListView;
import javafx.scene.control.TextField;
import javafx.util.StringConverter;

@ViewController.ViewName(View.DASHBOARD_ADD_MODIFY_BOOKS)
@ViewController.AllowedRoles({UserRole.LIBRARIAN})
public class BookModifyViewController extends ViewController.UserAwareController
{
  private static final Logger logger = Logger.getLogger(
    BookModifyViewController.class.getName());

  private final LockableView lockableView = new LockableView();
  private final EventBus eventBus = EventBus.get();

  /* All books tab */
  @FXML private ListView<Books> lvAllBooks;

  /* Add book tab */
  @FXML private TextField tfBookIsbn;
  @FXML private TextField tfBookTitle;
  @FXML private DatePicker dpBookPublishDate;
  @FXML private ComboBox<Authors> cbBookAuthor;
  @FXML private ListView<Authors> lvBookAuthors;
  @FXML private TextField tfPhysicalQty;
  @FXML private TextField tfDigitalUrl;
  @FXML private CheckBox cbIsPhysical;
  @FXML private CheckBox cbIsDigital;
  
  private FilteredList<Authors> filteredAuthors;

  @FXML
  private void initialize()
  {
    lockableView.lockableElements = List.of(
      tfBookIsbn, tfBookTitle, dpBookPublishDate, cbBookAuthor,
      lvBookAuthors, tfPhysicalQty, tfDigitalUrl, cbIsPhysical, cbIsDigital);
    tfPhysicalQty.setDisable(true);
    tfDigitalUrl.setDisable(true);
    lvAllBooks
      .getSelectionModel()
      .selectedItemProperty()
      .addListener(
        (_, _, selectedUser)
        -> eventBus.publish(new DashboardEvents.DashboardAuxSwapEvent<>(
            View.DASHBOARD_VIEW_BOOK_DETAIL, selectedUser)));
    
    cbBookAuthor.setConverter(
      new StringConverter<Authors>()
      {
        @Override
        public String toString(Authors author)
        {
          if (author == null)
            return "";
          return author.author_first_name() + " " + author.author_last_name();
        }

        @Override
        public Authors fromString(String string)
        {
          String[] parts = string.trim().split("\\s+", 2);
          if (parts.length == 2)
          {
            logger.info(
              "Parsed author from string: " + parts[0] + " " + parts[1]);
            return new Authors(-1, parts[0], parts[1]);
          }
          return null;
        }
      }
    );

    lvBookAuthors.setOnMouseClicked(
      event
      -> {
        if (event.getClickCount() == 2)
        {
          Authors selected
            = lvBookAuthors.getSelectionModel().getSelectedItem();
          if (selected != null)
            lvBookAuthors.getItems().remove(selected);
        }
      }
    );

    lvBookAuthors.setCellFactory(
      lv -> new ListCell<Authors>()
      {
        @Override
        protected void updateItem(Authors author, boolean empty)
        {
          super.updateItem(author, empty);
          setText(
            empty || author == null
            ? null
            : author.author_first_name() + " " + author.author_last_name()
          );
        }
      }
    );

    lockableView.lockView();
  }

  private void loadAuthors(List<Authors> authors)
  {
    cbBookAuthor.setButtonCell(
      new ListCell<>()
      {
        @Override
        protected void updateItem(Authors item, boolean empty)
        {
          super.updateItem(item, empty);
          setText(
            empty || item == null
            ? null
            : item.author_first_name() + " " + item.author_last_name()
          );
        }
      }
    );

    ObservableList<Authors> authorList
      = FXCollections.observableArrayList(authors);
    filteredAuthors = new FilteredList<>(authorList, a -> true);
    cbBookAuthor.getEditor().textProperty().addListener(
      (_, _, newVal)
      -> {
        String filter = newVal.toLowerCase();
        filteredAuthors.setPredicate(
          author
          -> {
            String fullName = (
              author.author_first_name() + " "
              + author.author_last_name()
            ).toLowerCase();
            return fullName.contains(filter);
          }
        );
        if (!filteredAuthors.isEmpty())
          cbBookAuthor.show();
      }
    );

    cbBookAuthor.setItems(filteredAuthors);
  }

  @Override
  public void whenUserAvailable(String userToken)
  {
    try
    {
      ResultType result = DatabaseFunctions.getAuthors(userToken);
      List<Authors> authors = result.getDataAsList(Authors.class);
      logger.info(
        "Fetched " + (authors != null ? authors.size() : 0)
        + " authors from database");
      if (authors != null)
        loadAuthors(authors);

    } catch (SQLException sqlExc)
    {
      logger.info("Failed to fetch authors for book modify view");
      throw new RuntimeException(
        "Failed to fetch authors for book modify view", sqlExc);
    }

    lockableView.unlockView();
  }

  @FXML
  private void onPhysicalChecked()
  {
    tfPhysicalQty.setDisable(!cbIsPhysical.isSelected());
  }

  @FXML
  private void onDigitalChecked()
  {
    tfDigitalUrl.setDisable(!cbIsDigital.isSelected());
  }

  @FXML
  private void onAddBookAuthor()
  {
    Authors selectedAuthor = cbBookAuthor.getValue();
    if (selectedAuthor != null)
    {
      lvBookAuthors.getItems().add(selectedAuthor);
      cbBookAuthor.getSelectionModel().clearSelection();
      cbBookAuthor.getEditor().clear();
    }
  }

  @FXML
  private void onAddBook()
  {
    lockableView.lockView();
    try
    {
      ResultType result = DatabaseFunctions.addBook(
        getBoundUserToken(),
        tfBookIsbn.getText(),
        tfBookTitle.getText(),
        dpBookPublishDate.getValue(),
        cbIsPhysical.isSelected()
          ? Integer.parseInt(tfPhysicalQty.getText()) : 0,
        cbIsDigital.isSelected());
      if (!result.success())
      {
        eventBus.publish(new Events.StatusMessageEvent(
          "Failed to add book: " + result.errorCode()));
        return;
      }
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      throw new RuntimeException("Failed to add book", sqlExc);
    } finally
    {
      lockableView.unlockView();
    }

    try
    {
      for (Authors author : lvBookAuthors.getItems())
      {
        ResultType result = DatabaseFunctions.addAuthor(
          getBoundUserToken(), tfBookIsbn.getText(), author.author_first_name(),
          author.author_last_name(),
          author.author_id() == -1? null : author.author_id());
        if (!result.success())
        {
          eventBus.publish(new Events.StatusMessageEvent(
            "Failed to add book author: " + result.errorCode()));
        }
      }
    } catch (SQLException sqlExc)
    {
      eventBus.publish(
        new Events.AlertEvent(AlertType.ERROR, "db.connection.error"));
      throw new RuntimeException("Failed to add book authors", sqlExc);
    } finally
    {
      lockableView.unlockView();
    }
  }
}
