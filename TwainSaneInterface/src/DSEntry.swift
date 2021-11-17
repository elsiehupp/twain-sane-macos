import Twain
import DataSource

var datasource: DataSource

func DS_Entry(
    pOrigin: Twain.Identity,
    DG: Int,
    DAT: Int,
    message: Int,
    pData: Twain.MemoryReference) -> Int {

    return datasource.Entry(pOrigin, DG, DAT, message, pData)
}
