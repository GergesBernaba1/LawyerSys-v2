import { useEffect, useRef } from "react";

/**
 * Warns the user before leaving the page (browser tab close / hard navigation)
 * when `isDirty` is true. Soft navigation (Next.js router.push) is NOT covered
 * by this hook — use the `onBeforeNavigate` return value together with a
 * confirmation dialog for that case.
 *
 * Usage:
 *   const { onBeforeNavigate } = useUnsavedChanges(isDirty);
 *   // then in a link/button: await onBeforeNavigate() before router.push(...)
 */
export default function useUnsavedChanges(isDirty: boolean) {
  const isDirtyRef = useRef(isDirty);
  useEffect(() => {
    isDirtyRef.current = isDirty;
  }, [isDirty]);

  useEffect(() => {
    const handler = (event: BeforeUnloadEvent) => {
      if (!isDirtyRef.current) return;
      event.preventDefault();
      // Modern browsers show their own generic message; setting returnValue
      // is required to trigger the dialog in older browsers.
      event.returnValue = "";
    };

    window.addEventListener("beforeunload", handler);
    return () => window.removeEventListener("beforeunload", handler);
  }, []);

  /**
   * Call this before any programmatic navigation (router.push / router.replace).
   * Returns true if navigation should proceed (user confirmed or no dirty state).
   */
  async function onBeforeNavigate(
    confirm: (message: string) => Promise<boolean>,
    message = "You have unsaved changes. Leave without saving?"
  ): Promise<boolean> {
    if (!isDirtyRef.current) return true;
    return confirm(message);
  }

  return { onBeforeNavigate };
}
