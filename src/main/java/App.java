import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.lang.StringUtils;

/*
 * This Java source file was generated by the Gradle 'init' task.
 */
public class App {
    public String getGreeting() {
        return "Hello world.";
    }

    public static void main(String[] args) {
        System.out.println(new App().getGreeting());
    }

    public String parseGavString(final List<String> textProtoStringList) throws Exception {
        final List<Map<String, String>> resultsTargetAttributeObjects = parseResultsTargetAttributeObjects(textProtoStringList);
        final Map<String, String> artifactObject = findArtifactObject(resultsTargetAttributeObjects);
        return getValueFromArtifactObject(artifactObject);
    }

    private String getValueFromArtifactObject(final Map<String, String> artifactObject) throws Exception {
        final String value = artifactObject.get("string_value");
        if (StringUtils.isNotBlank(value)) {
            return value;
        }
        throw new Exception(String.format("Value not found in artifact object: %s", artifactObject));
    }

    private Map<String, String> findArtifactObject(final List<Map<String, String>> resultsTargetAttributeObjects) throws Exception {
        for (int i=0; i < resultsTargetAttributeObjects.size(); i++) {
            final Map<String, String> currentAttributeObject = resultsTargetAttributeObjects.get(i);
            System.out.println(String.format("Read resultsTargetAttributeObject: %s", currentAttributeObject));
            final String name = currentAttributeObject.get("name");
            if ("artifact".equals(name)) {
                return currentAttributeObject;
            }
        }
        throw new Exception("Artifact Object not found");
    }

    private List<Map<String, String>> parseResultsTargetAttributeObjects(final List<String> textProtoStringList) {
        final List<Map<String, String>> resultsTargetAttributeObjects = new ArrayList<>();
        boolean inAttribute = false;
        // :grandparent:parent:currentobject
        String currentObjectLineage = "";
        String currentObjectName = null;
        for (final String line : textProtoStringList) {
            System.out.println(line);
            if (!isObjectStart(line) && !isObjectEnd(line) && inAttribute) {
                final String fieldName = getFieldName(line);
                final String fieldValue = getFieldValue(line);
                final Map<String, String> currentAttributeObject = resultsTargetAttributeObjects.get(resultsTargetAttributeObjects.size()-1);
                currentAttributeObject.put(fieldName, fieldValue);
            }
            if (isObjectStart(line)) {
                currentObjectName = getObjectName(line);
                currentObjectLineage = String.format("%s:%s", currentObjectLineage, currentObjectName);
                if (":results:target:rule:attribute".equals(currentObjectLineage)) {
                    inAttribute = true;
                    resultsTargetAttributeObjects.add(new HashMap<>());
                }
            } else if (isObjectEnd(line)) {
                if (inAttribute) {
                    inAttribute = false;
                    currentObjectLineage = popObjectLineage(currentObjectLineage);
                }
            }
        }
        return resultsTargetAttributeObjects;
    }

    String popObjectLineage(final String oldObjectLineage) {
        final int lastColonIndex = oldObjectLineage.lastIndexOf(':');
        final String newObjectLineage = oldObjectLineage.substring(0, lastColonIndex);
        return newObjectLineage;
    }
    String getFieldValue(final String line) {
        final String trimmedLine = line.trim();
        int colonIndex = trimmedLine.indexOf(':');
        if (colonIndex < 0) {
            return "";
        }
        final String fieldValueQuoted = trimmedLine.substring(colonIndex+1).trim();
        final String fieldValue;
        if (fieldValueQuoted.startsWith("\"") || fieldValueQuoted.startsWith("'")) {
            fieldValue = fieldValueQuoted.substring(1, fieldValueQuoted.length()-1);
        } else {
            // it's actually not quoted
            fieldValue = fieldValueQuoted;
        }
        return fieldValue;
    }

    String getFieldName(final String line) {
        final String trimmedLine = line.trim();
        int colonIndex = trimmedLine.indexOf(':');
        if (colonIndex < 0) {
            return "";
        }
        final String fieldName = trimmedLine.substring(0, colonIndex);
        return fieldName;
    }

    boolean isObjectEnd(final String line) {
        return line.endsWith("}");
    }

    boolean isObjectStart(final String line) {
        return line.endsWith("{");
    }

    String getObjectName(final String line) {
        return line.substring(0, line.length()-1).trim();
    }
}
