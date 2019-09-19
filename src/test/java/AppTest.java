/*
 * This Java source file was generated by the Gradle 'init' task.
 */
import org.apache.commons.io.FileUtils;
import org.junit.Test;
import static org.junit.Assert.*;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

public class AppTest {

    @Test
    public void testParseGavFromTextProto() throws Exception {
        final File textProtoFile = new File("src/test/resources/sample.textproto");
        final List<String> textProtoStringList = FileUtils.readLines(textProtoFile, StandardCharsets.UTF_8);
        final App app = new App();
        final String gavString = app.parseGavString(textProtoStringList);
        assertEquals("org.apache.commons:commons-io:1.3.2", gavString);
    }

    @Test
    public void testGetObjectName() {
        final App app = new App();
        assertEquals("myobject", app.getObjectName("    myobject {"));
    }

    @Test
    public void testGetFieldName() {
        final App app = new App();
        assertEquals("name", app.getFieldName("    name: \"artifact\""));
    }

    @Test
    public void testGetFieldValue() {
        final App app = new App();
        assertEquals("artifact", app.getFieldValue("    name: \"artifact\""));
    }

    @Test
    public void testPopObjectLineage() {
        final App app = new App();
        assertEquals(":results:target:rule", app.popObjectLineage(":results:target:rule:attribute"));
    }
}
