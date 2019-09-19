package misc;

import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebElement;

public class Selenium {

  private final static String NEXT_SIBLING_XPATH = "./following-sibling::";

  /**
   * Returns the following sibling of the specified element, or null if it
   * doesn't exist
   * @param elem the element to get the sibling of
   * @return the following sibling of the specified element with the same tag
   */
  static WebElement getFollowingSibling(WebElement elem) {
    try {
      return elem.findElement(By.xpath(NEXT_SIBLING_XPATH + elem.getTagName()));
    } catch (NoSuchElementException e) {
      return null;
    }
  }

  /**
   * Returns the following sibling of the specified element, or null if it
   * doesn't exist. Loops to make sure the next element has time to load.
   * @param elem the element to get the sibling of
   * @return the following sibling of the specified element with the same tag
   */
  static WebElement getNextLoop(WebElement elem) {
    WebElement elem2 = getFollowingSibling(elem);
    int counter = 0;
    while (elem2 == null && counter < 1000) {
      elem2 = getFollowingSibling(elem);
      try {
        Thread.sleep(10);
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
      counter++;
    }
    if (elem2 == null)
      throw new TimeoutException(
          "Feed page took too long to load another post.");
    return elem2;
  }
}
