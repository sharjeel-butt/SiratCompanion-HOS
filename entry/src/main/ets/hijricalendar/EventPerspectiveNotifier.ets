// entry/src/main/ets/utils/EventPerspectiveNotifier.ets

export type EventPerspectiveListener = () => void;

/**
 * Fan-out for Event Perspective changes.
 *
 * @StorageLink + @Watch on a shared AppStorage key does not fire
 * for changes that happen while a component is suspended behind a
 * routed page. Direct callbacks do — the notify() runs in the
 * caller's stack, so every subscriber updates its state
 * immediately, ready for the next render pass.
 */
export class EventPerspectiveNotifier {
  private static listeners: EventPerspectiveListener[] = [];

  static subscribe(fn: EventPerspectiveListener): void {
    if (EventPerspectiveNotifier.listeners.indexOf(fn) === -1) {
      EventPerspectiveNotifier.listeners.push(fn);
    }
  }

  static unsubscribe(fn: EventPerspectiveListener): void {
    EventPerspectiveNotifier.listeners =
      EventPerspectiveNotifier.listeners.filter(
        (l: EventPerspectiveListener): boolean => l !== fn
      );
  }

  static notify(): void {
    for (const fn of EventPerspectiveNotifier.listeners) {
      try {
        fn();
      } catch (e) {
        console.error(
          '[EventPerspectiveNotifier] listener failed: '
            + JSON.stringify(e)
        );
      }
    }
  }
}