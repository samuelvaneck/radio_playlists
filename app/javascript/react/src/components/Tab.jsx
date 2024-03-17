import * as React from 'react'

function Tab(props) {
    const name = props.name
    const searchPath = props.searchPath
    const tabIndex = props.tabIndex
    const activeTab = props.activeTab
    const onTabClick = props.onTabClick

    return(
        <li className="flex-auto me-2" onClick={() => onTabClick(tabIndex)}>
            <button className={`inline-block p-4 border-b-2 rounded-t-lg tab-btn ${activeTab === tabIndex ? 'tab-active active' : ''}`}
                    data-tab={`tab-${name}`}
                    data-search-url={searchPath}>
                {name}
            </button>
        </li>
    )
}

export default Tab
