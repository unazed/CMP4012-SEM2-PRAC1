package com.unazed.LibraryManagement;

import java.util.ArrayList;
import java.util.List;

import javafx.scene.Node;

public class LockableView
{
  private boolean isLocked = false;
  public List<Node> lockableElements;
  private List<Node> lockedElements = new ArrayList<>();

  public void lockView()
  {
    if (isLocked)
      return;
    lockableElements.forEach(
      node ->
      {
        if (node.isDisable())
          lockedElements.add(node);
        node.setDisable(true);
      }
    );
    isLocked = true;
  }

  public void unlockView()
  {
    if (!isLocked)
      return;
    lockableElements.forEach(
      node ->
      {
        if (!lockedElements.contains(node))
          node.setDisable(false);
      }
    );
    lockedElements.clear();
    isLocked = false;
  }
}
