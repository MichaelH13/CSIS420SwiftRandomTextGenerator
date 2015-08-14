// General import statement for Swift.
import Foundation

/*
Wrapper class to simplify file IO.
*/
public class File
{
    /*
    Class function. Accepts a file path and String encoding as arguments
    and returns an optional String representing the file contents, if there
    is no readable file at the given path, nil is returned.
    
    @parameter path The path to find the file to read at.
    
    @parameter utf8 The String encoding to use when performing IO on the 
    file given.
    
    @return an optional string representing the contents of the file at the
    path provided.
    */
    class func open (path: String, utf8: NSStringEncoding = NSUTF8StringEncoding) -> String?
    {
        var error: NSError?
        return NSFileManager().fileExistsAtPath(path) ?
            String(contentsOfFile: path, encoding: utf8, error: nil)! : nil
    }
    
    /*
    Class function. Accepts a file path and String encoding as arguments
    and returns an optional String representing the file contents, if there
    is no readable file at the given path, nil is returned.
    
    @parameter path The path to write the String argument content to.
    
    @parameter content The String to write to the file path provided.
    
    @return true if the content was successfully written to file, otherwise
    false.
    */
    class func save (path: String, _ content: String,
        utf8: NSStringEncoding = NSUTF8StringEncoding) -> Bool
    {
        var error: NSError?
        return content.writeToFile(path, atomically: true, encoding: utf8, error: &error)
    }
}


/*
Compares two ParseSymbols for equality. Returns true if the ParseSymbols
are equal, false otherwise

@return true if the ParseSymbols are equal, otherwise false.
*/
public func ==(lhs: ParseSymbol, rhs: ParseSymbol)->Bool
{
    // Return the comparison of the values of the ParseSymbols.
    return lhs._value == rhs._value
}

/*
Class for holding a ParseSymbol. A ParseSymbol implements protocols 
Hashable and Printable.
*/
public class ParseSymbol: Printable, Hashable
{
    /*
    Constructor for the object, sets the value parameter to be the internal
    representation of the ParseSymbol.
    */
    public init(value: String)
    {
        // Initialize instance variable.
        _value = value
    }
    
    /*
    Implementing the Hashable protocol with a getter for
    */
    public var hashValue: Int
    {
        // Note, no formal declaration needed here as the declaration of
        // the protocol does this for us.
        get
        {
            // Return the Hashvalue of the instance variable.
            return _value.hashValue
        }
    }
    
    /*
    Implementing the Printable protocol with a getter for the private
    var description.
    */
    public var description: String
    {
        // Note, no formal declaration needed here as the declaration of
        // the protocol does this for us.
        get
        {
            // Get description method to implement printable protocol.
            // Return the symbol's value.
            return _value
        }
    }
    
    /*
    Returns true if the ParseSymbol is non-terminal, false otherwise.
    @return true if the ParseSymbol is non-terminal, false otherwise.
    */
    public func isNonTerminal()->Bool
    {
        // Return a logical AND of whether or not _value has "<" at its
        // first index and an ">" at its last index.
        return _value.hasPrefix(PREFIX_OF_TERMINAL) &&
            _value.hasSuffix(SUFFIX_OF_TERMINAL)
    }
    
    /*
    Returns true if the ParseSymbol is terminal, false otherwise.
    @return true if the ParseSymbol is terminal, false otherwise.
    */
    public func isTerminal()->Bool
    {
        // Return the inverse of isNonTerminal.
        return !isNonTerminal()
    }
    
    // Class constants.
    private let PREFIX_OF_TERMINAL = "<"
    private let SUFFIX_OF_TERMINAL = ">"
    
    // Instance variables.
    private var _value: String
    
} // ParseSymbol: Printable, Hashable

/*
Class for creating a Grammar from the given input.
*/
public class Grammar
{
    /*
    Create a Grammar with the file at the file path provided as an 
    argument.
    @parameter filePath The File path to find the file containing the
    Grammar to be generated.
    */
    public init(filePath: String)
    {
        // Initialize constants.
        let START = "{"
        let END = "}"
        let BODY_END = ";"
        
        // This variable will represent the grammar file.
        var grammarFile: String?
        
        // The algorithm uses a simple finite-state-machine to parse the
        // input. These flags are used to tell what state we're in while
        // processing a particular grammar production.
        var readingAProduction = false
        var readingBodies = false
        
        // These variables are used during parsing to represent parts of
        // productions.
        var leftHandSideSymbol: ParseSymbol!
        
        // Initialize a String array to hold the contents of the file.
        var symbolsToProcess: [String]
        
        // Initialize our symbol table and an array to keep track of the
        // ParseSymbols we have encountered while reading the file.
        var symbolList: [ParseSymbol] = []
        _symbolTable = Dictionary<ParseSymbol, Array<Array<ParseSymbol>>>()
        
        // Attempt to get the data at the filePath provided.
        grammarFile = File.open(filePath)
        
        // If we were able to access the data in our grammar file, begin to
        // process the grammar file.
        if ((grammarFile) != nil)
        {
            // Remove \r\n literals that prevent proper processing of the
            // grammarFile.
            grammarFile = grammarFile!.stringByReplacingOccurrencesOfString("\r\n", withString: " ", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            // For each symbol in the grammar file provided, determine if
            // the symbol should be placed as a production or as a body for
            // a production.
            for currentSymbol in grammarFile!.componentsSeparatedByString(" ")
            {
                // If we are not reading a production currently, set 
                // readingAProduction to the result of the boolean
                // comparison of currentSymbol to the START constant.
                if (!readingAProduction)
                {
                    // Set readingAProduction to the result of the boolean
                    // comparison of currentSymbol to the START constant.
                    readingAProduction = currentSymbol == START
                }
                // Else if currentSymbol is the end of a production, then
                // set readingAProduction and readingBodies to false.
                else if (currentSymbol == END)
                {
                    // Set readingAProduction and readingBodies to false.
                    readingAProduction = false
                    readingBodies = false
                }
                // Else we are reading a production so this is the head 
                // or bodies of a production.
                else
                {
                    // If we are not reading bodies, then get the next
                    // ParseSymbol, create a new Array of Arrays holding
                    // ParseSymbol to store the bodies of the production.
                    // Then set readingBodies to true and Initialize the
                    // Grammar _startSymbol if it has not beed initialized.
                    if (!readingBodies)
                    {
                        // Set leftHandSideSymbol to be a ParseSymbol 
                        // holding the String currentSymbol.
                        leftHandSideSymbol = ParseSymbol(value: currentSymbol)
                        
                        // Create a new Array of Arrays holding ParseSymbol
                        // that can be referenceed by their ParseSymbol.
                        _symbolTable[leftHandSideSymbol] = Array<Array<ParseSymbol>>()
                        
                        // Set readingBodies to true so we can begin
                        // reading in the bodies for leftHandSideSymbol
                        // sentences.
                        readingBodies = true
                        
                        // If we have not gotten our _startSymbol yet, set
                        // the leftHandSideSymbol to be our _startSymbol.
                        if ((_startSymbol) == nil)
                        {
                            // Set the leftHandSideSymbol to be our 
                            // _startSymbol.
                            _startSymbol = leftHandSideSymbol
                        }
                    }
                    // We are reading in body of a production.
                    else
                    {
                        // If the currentSymbol is equal to BODY_END then
                        // add the symbolList to the list of bodies in for
                        // the ParseSymbol leftHandSideSymbol.
                        if (currentSymbol == BODY_END)
                        {
                            // Add the symbolList to the list of bodies in
                            // for the ParseSymbol leftHandSideSymbol.
                            _symbolTable[leftHandSideSymbol]!.append(symbolList)
                            
                            // Remove all elements from our symbolList and
                            // keep the current capacity by passing true as
                            // an argument.
                            symbolList.removeAll(keepCapacity: true)
                        }
                        // We are still readingBodies so process the
                        // currentSymbol.
                        else
                        {
                            // If the currentSymbol is a newline, then
                            // add a newline character to the symbolList.
                            if (currentSymbol == "\\n")
                            {
                                // Add a newline character to the symbolList.
                                symbolList.append(ParseSymbol(value: "\n"))
                            }
                            // Since currentSymbol is not a new line, just
                            // add it to the symbolList.
                            else
                            {
                                // Add currentSymbol to the symbolList.
                                symbolList.append(ParseSymbol(value: currentSymbol))
                            }
                            
                        } // Body parsing
                        
                    } // Body or production reading
                }
            }
        }
    } // Constructor
    
    /*
    Function that returns the symbol table for the Grammar.
    
    @return the table of symbols and productions.
    */
    public func getSymbolTable()->Dictionary<ParseSymbol, Array<Array<ParseSymbol>>>
    {
        // Return the symbol table.
        return _symbolTable
    }
    
    /*
    Function that returns the start symbol for the Grammar.
    
    @return An optional ParseSymbol representing the start symbol for the
    Grammar.
    */
    public func getStartSymbol()->ParseSymbol?
    {
        // Return the optional start symbol.
        return _startSymbol
    }
    
    // Private attributes of a Grammar.
    private var _startSymbol: ParseSymbol?
    private var _symbolTable: Dictionary<ParseSymbol, Array<Array<ParseSymbol>>>
} // Class Grammar

/*
Class for generating sentences given a Grammar file as a command-line
argument.
*/
public class Generate
{
    /*
    The main algorithm for the program.
    */
    public class func Main()
    {
        // Initialize constants.
        let ARGS: [String] = Process.arguments
        let MIN_ARGS_LENGTH = 2
        let ERROR_MSG_USAGE: String = "Usage: swift \(ARGS[0]) [filepath]"
        let ERROR_MSG_READ_FILE: String = "ERROR: File could not be read."
        
        // Initialize variables.
        var theGrammar: Grammar?
        var stackSymbolsToProcess: [ParseSymbol] = []
        var symbolsToProcess: [ParseSymbol] = []
        var resultSentence: String = ""
        
        // If the number of arguments provided is less than the 
        // MIN_ARGS_LENGTH display the usage message.
        if (countElements(ARGS) < MIN_ARGS_LENGTH)
        {
            // Display the usage message.
            println(ERROR_MSG_USAGE)
        }
        
        // Attempt to get the Grammar with the file path provided.
        theGrammar = Grammar(filePath: ARGS[1])
        
        // If the Grammar is available then generate a sentence from it.
        // Otherwise display a usage message.
        if ((theGrammar!.getStartSymbol()) != nil)
        {
            // Add the initial ParseSymbol to the stack.
            stackSymbolsToProcess.append(theGrammar!.getStartSymbol()!)

            // While we still have ParseSymbols to process, continue to
            // resolve the non-terminal ParseSymbols and add the terminals
            // to our resultSentence.
            while (!stackSymbolsToProcess.isEmpty)
            {
                // If the current ParseSymbol is a terminal then just 
                // append it to our resultSentence.
                if (stackSymbolsToProcess.last!.isTerminal())
                {
                    // Get the current terminal ParseSymbol and append it 
                    // to our resultSentence and add a space after it for 
                    // readability.
                    resultSentence += stackSymbolsToProcess.removeLast().description + " "
                }
                // Else we are processing a non-terminal ParseSymbol.
                else
                {
                    // Get a list of the symbols that terminate the 
                    // current non terminal from the stack.
                    symbolsToProcess = theGrammar!.getSymbolTable()[stackSymbolsToProcess.last!]![Int(arc4random()) % countElements(theGrammar!.getSymbolTable()[stackSymbolsToProcess.removeLast()]!)]
                    
                    // While we still have symbols to process, append the
                    // last symbol to the stackSymbolsToProcess variable.
                    while (!symbolsToProcess.isEmpty)
                    {
                        // Append the last symbol to the
                        // stackSymbolsToProcess variable.
                        stackSymbolsToProcess.append(symbolsToProcess.removeLast())
                    }
                }
            }
        }
        
        // If the Grammar does not have a start symbol, then the file must
        // have thrown an error, so display a file error message and the
        // usage message for good measure.
        else
        {
            // Display an error message for file read error.
            println(ERROR_MSG_READ_FILE)
            println(ERROR_MSG_USAGE)
        }
        
        // Display the resultSentence to console.
        println(resultSentence)
    }
}

// Call the Main function.
Generate.Main()
