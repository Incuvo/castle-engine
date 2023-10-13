module.exports.excludeFromObject = (obj, excludedFields) ->
    for field in excludedFields
        if obj[field] == undefined
            continue
        delete obj[field]

    return obj


module.exports.roundToSignificantNumbers = (value, iSignificantNumbers) ->
    if iSignificantNumbers == 0
        return 0

    iCuttedDecimals = 0;

    fValue = value
    iBoundValue = parseInt(Math.Pow(10, iSignificantNumbers))

    if value >= 0
        while fValue > iBoundValue
            fValue /= 10.0
            iCuttedDecimals++
    else
        while  fValue < -iBoundValue
            fValue /= 10.0
            iCuttedDecimals++

    iRoundedValue = parseInt(fValue) * parseInt(Math.Pow(10, iCuttedDecimals))

    return iRoundedValue

#public static int RoundToSignificantNumbers(float value, int iSignificantNumbers)
#{
#    if (iSignificantNumbers == 0)
#        return 0;
#
#    int iCuttedDecimals = 0;
#
#    float fValue = value;
#    int iBoundValue = (int)Mathf.Pow(10, iSignificantNumbers);
#
#    if (value >= 0)
#    {
#        while (fValue > iBoundValue)
#        {
#            fValue /= 10.0f;
#            iCuttedDecimals++;
#        }
#    }
#    else
#    {
#        while (fValue < -iBoundValue)
#        {
#            fValue /= 10.0f;
#            iCuttedDecimals++;
#        }
#    }
#
#    int iRoundedValue = ((int)fValue) * (int)Mathf.Pow(10, iCuttedDecimals);
#
#    return iRoundedValue;
#}