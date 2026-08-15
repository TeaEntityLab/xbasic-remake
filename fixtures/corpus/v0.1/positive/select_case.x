VERSION "0.1"
FUNCTION Main
DIM x
DIM result
x = 2
SELECT CASE x
  CASE 1
    result = 100
  CASE 2
    result = 200
  CASE 3
    result = 300
  CASE ELSE
    result = 999
END SELECT
PRINT result

x = 5
SELECT CASE x
  CASE 1
    result = 100
  CASE 2, 3, 4
    result = 200
  CASE ELSE
    result = 999
END SELECT
PRINT result
END FUNCTION
