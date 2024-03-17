import * as React from 'react'

function Tab(props) {
    const name = props.name
    const searchPath = props.searchPath
    const tabIndex = props.tabIndex
    const activeTab = props.activeTab
    const onTabClick = props.onTabClick
    const dataTabAttribute = props.dataTabAttribute

    return(
        <li className="flex-auto me-2" onClick={() => onTabClick(event, tabIndex)}>
            <button className={`block w-full p-4 border-b-2 rounded-t-lg tab-btn ${activeTab === tabIndex ? 'tab-active active' : ''}`}
                    data-tab={dataTabAttribute}
                    data-search-url={searchPath}>
                {name}
            </button>
        </li>
    )
}

export default Tab
