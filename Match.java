public class Match {

    public static void main(String[] args) {
        // args is comprised of two lists, with the first list's length defined as the first element of args
        int firstLength = -1;
        try {
            firstLength = Integer.parseInt(args[0]);
        } catch (Exception e) {
            System.err.println("First argument to args must be the length of the list, instead it is " + args[0]);
            System.exit(1);
        }

        var firstArray = new String[firstLength];
        var secondArray = new String[args.length - 1 - firstLength];

        int i;
        for (i = 0; i < firstLength; i++) firstArray[i] = args[i + 1];

        for (int j = i; j < args.length - 1; j++) secondArray[j - i] = args[j + 1];

        compare(firstArray, secondArray);
    }

    static String msg; 

    // Print out a custom message of validation success vs failure
    static void compare(String[] firstArray, String[] secondArray) {
        if (validate(firstArray, secondArray))
            System.err.println("Test succeeded");
        else
            System.err.println("Test failed" + (msg == null ? "" : " " + msg));
    }

    static boolean validate(String[] firstArray, String[] secondArray) {
        if (firstArray.length != secondArray.length) {
            int i = 0;
            i = 0;
            msg = "because file1 outputs " + firstArray.length + " lines vs file2 having " + secondArray.length;
            return false;
        }
        for (int i = 0; i < firstArray.length; i++)
            if (!firstArray[i].equals(secondArray[i])) {
                msg = "at line " + i;
                return false;
            }
        
        return true;
    }
}
