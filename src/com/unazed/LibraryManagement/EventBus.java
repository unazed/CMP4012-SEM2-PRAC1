package com.unazed.LibraryManagement;

import java.util.*;
import java.util.function.Consumer;

public class EventBus
{
  private static final EventBus INSTANCE = new EventBus();
  private final Map<Class<?>, List<Consumer<Object>>> listeners
    = new HashMap<>();

  public static EventBus get()
  {
    return INSTANCE;
  }

  public <T> void subscribe(Class<T> event, Consumer<T> listener)
  {
    listeners
      .computeIfAbsent(event, k -> new ArrayList<>())
      .add(e -> listener.accept((T) e));
  }

  public void publish(Object event)
  {
    listeners
      .getOrDefault(event.getClass(), List.of())
      .forEach(l -> l.accept(event));
  }
}