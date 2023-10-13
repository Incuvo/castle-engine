aesEnc  = require './aes-enc'

module.exports.encode = (dataIn, key, blockSize = 16) ->

    bufferData = new Buffer(dataIn)

    bufferDataPadLen = blockSize - (bufferData.length % blockSize)

    if bufferDataPadLen > 0
        padBuffer = new Buffer( bufferDataPadLen )
        padBuffer.fill(bufferDataPadLen)
        bufferData = Buffer.concat([bufferData, padBuffer])

    keyExpansion = new aesEnc.keyExpansion('eTIh4CUcBHSu745pdWAtAJyhG1BUMe8K')

    for padOffset in [0...bufferData.length] by 16
        aesEnc.AESencrypt(bufferData.slice(padOffset, padOffset + 16) , keyExpansion)

    return bufferData